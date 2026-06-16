import { Mousetrap } from '~/lib/mousetrap';
import {
  keysFor,
  MR_NEXT_FILE_IN_DIFF,
  MR_PREVIOUS_FILE_IN_DIFF,
  MR_COMMITS_NEXT_COMMIT,
  MR_COMMITS_PREVIOUS_COMMIT,
  MR_TOGGLE_REVIEW,
} from '~/behaviors/shortcuts/keybindings';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { pinia } from '~/pinia/instance';
import { useMergeRequestVersions } from '~/merge_request/stores/merge_request_versions';
import { useCodeReview } from '~/diffs/stores/code_review';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import { COLLAPSE_FILE_BY_USER, EXPAND_FILE } from '~/rapid_diffs/adapter_events';

function clampIndex(index, length) {
  if (length === 0) return -1;
  return Math.max(0, Math.min(index, length - 1));
}

export function createFileNavigation() {
  let currentIndex = 0;

  return {
    jumpToFile(step) {
      const files = DiffFile.getAll();
      if (files.length === 0) return;

      currentIndex = clampIndex(currentIndex, files.length);
      const targetIndex = currentIndex + step;

      if (targetIndex >= 0 && targetIndex < files.length) {
        currentIndex = targetIndex;
        files[targetIndex].selectFile();
      }
    },
    getCurrentFile() {
      const files = DiffFile.getAll();
      if (files.length === 0) return null;

      currentIndex = clampIndex(currentIndex, files.length);
      return files[currentIndex];
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
  } else {
    file.trigger(EXPAND_FILE);
  }
}

export function initHotkeys() {
  if (shouldDisableShortcuts()) return () => {};

  const nav = createFileNavigation();

  const bindings = [
    [keysFor(MR_NEXT_FILE_IN_DIFF), () => nav.jumpToFile(+1)],
    [keysFor(MR_PREVIOUS_FILE_IN_DIFF), () => nav.jumpToFile(-1)],
    [keysFor(MR_COMMITS_NEXT_COMMIT), () => navigateCommit('next')],
    [keysFor(MR_COMMITS_PREVIOUS_COMMIT), () => navigateCommit('previous')],
    [keysFor(MR_TOGGLE_REVIEW), () => toggleFileReview(nav.getCurrentFile())],
  ];

  bindings.forEach(([keys, handler]) => Mousetrap.bind(keys, handler));

  return () => {
    bindings.forEach(([keys]) => Mousetrap.unbind(keys));
  };
}
