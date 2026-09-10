import { Mousetrap } from '~/lib/mousetrap';
import {
  keysFor,
  MR_NEXT_FILE_IN_DIFF,
  MR_PREVIOUS_FILE_IN_DIFF,
  MR_COMMITS_NEXT_COMMIT,
  MR_COMMITS_PREVIOUS_COMMIT,
  MR_TOGGLE_REVIEW,
  MR_TOGGLE_DIFF_VIEW_TYPE,
  ISSUABLE_COMMENT_OR_REPLY,
} from '~/behaviors/shortcuts/keybindings';
import { keyboardShortcutsDisabled } from '~/behaviors/shortcuts/shortcuts_disabled';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { pinia } from '~/pinia/instance';
import { useMergeRequestVersions } from '~/merge_request/stores/merge_request_versions';
import { useCodeReview } from '~/diffs/stores/code_review';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { INLINE_DIFF_VIEW_TYPE, PARALLEL_DIFF_VIEW_TYPE } from '~/diffs/constants';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import { COLLAPSE_FILE_BY_USER, EXPAND_FILE } from '~/rapid_diffs/adapter_events';
import { querySelectionClosest } from '~/lib/utils/selection';
import { getCoveringElementSync } from '~/lib/utils/viewport';

function diffsViewportRect(files) {
  let top = 0;

  const covering = getCoveringElementSync(files[0]);

  if (covering) {
    top = covering.getBoundingClientRect().bottom;
  }

  return { top, bottom: window.innerHeight };
}

// The file the reader is looking at: the one with the greatest height visible
// inside the diffs viewport (below the sticky header). Ties resolve to the
// upper file so small scroll jitter does not flip the selection.
function mostVisibleFileIndex(files) {
  const viewport = diffsViewportRect(files);

  let mostVisibleIndex = files.length - 1;
  let greatestVisibleHeight = -1;

  files.forEach((file, index) => {
    const rect = file.getBoundingClientRect();
    const visibleHeight = Math.min(rect.bottom, viewport.bottom) - Math.max(rect.top, viewport.top);

    if (visibleHeight > greatestVisibleHeight) {
      greatestVisibleHeight = visibleHeight;
      mostVisibleIndex = index;
    }
  });

  return mostVisibleIndex;
}

// User-initiated viewport movement; programmatic selectFile scrolling fires
// only 'scroll', which is deliberately not listened to here.
const USER_MOVEMENT_EVENTS = ['wheel', 'touchmove', 'mousedown'];

export function createFileNavigation() {
  let cursor = null;

  const invalidateCursor = () => {
    cursor = null;
  };

  USER_MOVEMENT_EVENTS.forEach((event) => {
    window.addEventListener(event, invalidateCursor, { capture: true, passive: true });
  });

  return {
    teardown() {
      USER_MOVEMENT_EVENTS.forEach((event) => {
        window.removeEventListener(event, invalidateCursor, { capture: true });
      });
    },
    jumpToFile(step) {
      const view = useDiffsView(pinia);
      const files = DiffFile.getAll();

      if (view.singleFileMode) {
        if (step > 0) {
          view.goToNextFile();
        } else {
          view.goToPrevFile();
        }
      } else if (files.length > 0) {
        // A scroll or click since the last jump means the reader moved; restart
        // from the file they are looking at. Otherwise step from the cursor so
        // repeated presses never stall on or skip past short files.
        const anchor = cursor ?? mostVisibleFileIndex(files);
        const targetIndex = anchor + step;

        if (targetIndex >= 0 && targetIndex < files.length) {
          cursor = targetIndex;
          files[targetIndex].selectFile();
        }
      }
    },
    getCurrentFile() {
      const view = useDiffsView(pinia);
      const files = DiffFile.getAll();

      let index = -1;

      if (view.singleFileMode) {
        index = 0;
      } else if (files.length > 0) {
        index = cursor ?? mostVisibleFileIndex(files);
      }

      return files[index] ?? null;
    },
  };
}

export function navigateCommit(direction) {
  const { commit } = useMergeRequestVersions(pinia);
  if (!commit) return;

  const commitIds = {
    next: commit.next_commit_id,
    previous: commit.prev_commit_id,
  };
  const commitId = commitIds[direction];
  if (!commitId) return;

  visitUrl(setUrlParams({ commit_id: commitId }));
}

export function toggleFileReview(file) {
  const fileId = file?.data?.codeReviewId;
  if (!fileId) return;

  const store = useCodeReview(pinia);
  const isViewed = !store.reviewedIds[fileId];

  store.setReviewed(fileId, isViewed);
  file.diffElement?.toggleAttribute('data-viewed', isViewed);

  const checkbox = file.diffElement?.querySelector('[data-viewed-checkbox]');
  if (checkbox) {
    checkbox.checked = isViewed;
  }

  if (isViewed) {
    file.trigger(COLLAPSE_FILE_BY_USER);
    // Collapsing can pull the file above the fold; keep its header in view.
    file.selectFile();
  } else {
    file.trigger(EXPAND_FILE);
  }
}

export function quoteReply() {
  const container = querySelectionClosest('.js-discussion-container');
  if (!container) return;

  container.dispatchEvent(new CustomEvent('quoteReply'));
}

export function toggleDiffViewType() {
  const store = useDiffsView(pinia);
  const nextViewType =
    store.viewType === INLINE_DIFF_VIEW_TYPE ? PARALLEL_DIFF_VIEW_TYPE : INLINE_DIFF_VIEW_TYPE;

  store.updateViewType(nextViewType);
}

export function initHotkeys({ mergeRequestShortcuts = true } = {}) {
  if (keyboardShortcutsDisabled()) return () => {};

  const nav = createFileNavigation();

  const bindings = [
    [keysFor(MR_NEXT_FILE_IN_DIFF), () => nav.jumpToFile(+1)],
    [keysFor(MR_PREVIOUS_FILE_IN_DIFF), () => nav.jumpToFile(-1)],
    [keysFor(MR_TOGGLE_DIFF_VIEW_TYPE), () => toggleDiffViewType()],
    [keysFor(ISSUABLE_COMMENT_OR_REPLY), () => quoteReply()],
    ...(mergeRequestShortcuts
      ? [
          [keysFor(MR_COMMITS_NEXT_COMMIT), () => navigateCommit('next')],
          [keysFor(MR_COMMITS_PREVIOUS_COMMIT), () => navigateCommit('previous')],
          [keysFor(MR_TOGGLE_REVIEW), () => toggleFileReview(nav.getCurrentFile())],
        ]
      : []),
  ];

  bindings.forEach(([keys, handler]) => Mousetrap.bind(keys, handler));

  return () => {
    bindings.forEach(([keys]) => Mousetrap.unbind(keys));
    nav.teardown();
  };
}
