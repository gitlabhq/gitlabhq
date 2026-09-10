import { createTestingPinia } from '@pinia/testing';
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
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { visitUrl } from '~/lib/utils/url_utility';
import { useMergeRequestVersions } from '~/merge_request/stores/merge_request_versions';
import { useCodeReview } from '~/diffs/stores/code_review';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { INLINE_DIFF_VIEW_TYPE, PARALLEL_DIFF_VIEW_TYPE } from '~/diffs/constants';
import { COLLAPSE_FILE_BY_USER, EXPAND_FILE } from '~/rapid_diffs/adapter_events';
import { getCoveringElementSync } from '~/lib/utils/viewport';
import {
  initHotkeys,
  createFileNavigation,
  navigateCommit,
  toggleFileReview,
  toggleDiffViewType,
  quoteReply,
} from '~/rapid_diffs/app/init_hotkeys';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

jest.mock('~/lib/utils/viewport', () => ({
  getCoveringElementSync: jest.fn(() => null),
}));

const DEFAULT_VIEWPORT_HEIGHT = 1000;

// Builds diff-file stand-ins from [top, bottom] rects. The "current" file is
// the one with the greatest height visible between the sticky header bottom
// and the window bottom.
const makeFilesAt = (rects) =>
  rects.map(([top, bottom], index) => ({
    id: String.fromCharCode(97 + index),
    selectFile: jest.fn(),
    getBoundingClientRect: () => ({ top, bottom }),
  }));

const withStickyHeaderBottom = (value) => {
  getCoveringElementSync.mockReturnValue({ getBoundingClientRect: () => ({ bottom: value }) });
};

describe('initHotkeys', () => {
  let teardown;

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    window.gon = { keyboard_shortcuts_enabled: true };
  });

  afterEach(() => {
    teardown?.();
    teardown = null;
    Mousetrap.reset();
    getCoveringElementSync.mockReturnValue(null);
    window.gon = {};
  });

  describe('createFileNavigation', () => {
    describe('multi-file mode', () => {
      beforeEach(() => {
        useDiffsView().singleFileMode = false;
        window.innerHeight = DEFAULT_VIEWPORT_HEIGHT;
      });

      it('treats the most visible file as current', () => {
        const nav = createFileNavigation();
        const files = makeFilesAt([
          [-500, 120],
          [120, 700],
          [700, 3000],
        ]);
        jest.spyOn(DiffFile, 'getAll').mockReturnValue(files);

        expect(nav.getCurrentFile().id).toBe('b');
      });

      it('clips visibility below the sticky header', () => {
        const nav = createFileNavigation();
        const files = makeFilesAt([
          [-500, 400],
          [400, 990],
        ]);
        jest.spyOn(DiffFile, 'getAll').mockReturnValue(files);
        withStickyHeaderBottom(350);

        expect(nav.getCurrentFile().id).toBe('b');
      });

      it('advances forward from the most visible file', () => {
        const nav = createFileNavigation();
        const files = makeFilesAt([
          [-500, 120],
          [120, 700],
          [700, 3000],
        ]);
        jest.spyOn(DiffFile, 'getAll').mockReturnValue(files);

        nav.jumpToFile(+1);

        expect(files[2].selectFile).toHaveBeenCalled();
      });

      it('advances backward from the most visible file', () => {
        const nav = createFileNavigation();
        const files = makeFilesAt([
          [-500, 120],
          [120, 700],
          [700, 3000],
        ]);
        jest.spyOn(DiffFile, 'getAll').mockReturnValue(files);

        nav.jumpToFile(-1);

        expect(files[0].selectFile).toHaveBeenCalled();
      });

      it('advances on every repeated forward press without re-deriving from geometry', () => {
        const nav = createFileNavigation();
        const files = makeFilesAt([
          [0, 900],
          [900, 950],
          [950, 1000],
          [1000, 1050],
        ]);
        jest.spyOn(DiffFile, 'getAll').mockReturnValue(files);

        // Geometry never changes between presses (as when selectFile pins a
        // short file to the top); the cursor must still step 1 -> 2 -> 3.
        nav.jumpToFile(+1);
        nav.jumpToFile(+1);
        nav.jumpToFile(+1);

        expect(files[1].selectFile).toHaveBeenCalled();
        expect(files[2].selectFile).toHaveBeenCalled();
        expect(files[3].selectFile).toHaveBeenCalled();
      });

      it('resyncs to the most visible file after user scrolling', () => {
        const nav = createFileNavigation();
        const files = makeFilesAt([
          [0, 900],
          [900, 950],
          [950, 1000],
          [1000, 1050],
        ]);
        jest.spyOn(DiffFile, 'getAll').mockReturnValue(files);

        nav.jumpToFile(+1);
        expect(files[1].selectFile).toHaveBeenCalled();

        // The reader wheel-scrolls so file d fills the viewport.
        files[3].getBoundingClientRect = () => ({ top: 0, bottom: 900 });
        files[0].getBoundingClientRect = () => ({ top: -900, bottom: 0 });
        window.dispatchEvent(new Event('wheel'));

        nav.jumpToFile(-1);
        expect(files[2].selectFile).toHaveBeenCalled();
      });

      it('targets the navigated file with the review toggle', () => {
        const nav = createFileNavigation();
        const files = makeFilesAt([
          [0, 900],
          [900, 950],
          [950, 1000],
        ]);
        jest.spyOn(DiffFile, 'getAll').mockReturnValue(files);

        nav.jumpToFile(+1);

        expect(nav.getCurrentFile().id).toBe('b');
      });

      it('does not navigate past the last file', () => {
        const nav = createFileNavigation();
        const files = makeFilesAt([[0, 900]]);
        jest.spyOn(DiffFile, 'getAll').mockReturnValue(files);

        nav.jumpToFile(+1);

        expect(files[0].selectFile).not.toHaveBeenCalled();
      });

      it('does not navigate before the first file', () => {
        const nav = createFileNavigation();
        const files = makeFilesAt([[0, 900]]);
        jest.spyOn(DiffFile, 'getAll').mockReturnValue(files);

        nav.jumpToFile(-1);

        expect(files[0].selectFile).not.toHaveBeenCalled();
      });

      it('does nothing when there are no files', () => {
        const nav = createFileNavigation();
        jest.spyOn(DiffFile, 'getAll').mockReturnValue([]);

        nav.jumpToFile(+1);

        expect(nav.getCurrentFile()).toBeNull();
      });
    });

    describe('single-file mode', () => {
      beforeEach(() => {
        useDiffsView().singleFileMode = true;
      });

      it('delegates forward navigation to the store', () => {
        const goToNextFile = jest.spyOn(useDiffsView(), 'goToNextFile').mockImplementation();
        const nav = createFileNavigation();

        nav.jumpToFile(+1);

        expect(goToNextFile).toHaveBeenCalled();
      });

      it('delegates backward navigation to the store', () => {
        const goToPrevFile = jest.spyOn(useDiffsView(), 'goToPrevFile').mockImplementation();
        const nav = createFileNavigation();

        nav.jumpToFile(-1);

        expect(goToPrevFile).toHaveBeenCalled();
      });

      it('returns the single loaded file as current', () => {
        const nav = createFileNavigation();
        const files = makeFilesAt([[0, 900]]);
        jest.spyOn(DiffFile, 'getAll').mockReturnValue(files);

        expect(nav.getCurrentFile().id).toBe('a');
      });
    });
  });

  describe('file navigation keybindings', () => {
    const nextFileKey = keysFor(MR_NEXT_FILE_IN_DIFF)[0];
    const prevFileKey = keysFor(MR_PREVIOUS_FILE_IN_DIFF)[0];

    it('navigates forward and backward from the visible file', () => {
      useDiffsView().singleFileMode = false;
      const files = makeFilesAt([
        [-500, 120],
        [120, 700],
        [700, 3000],
      ]);
      jest.spyOn(DiffFile, 'getAll').mockReturnValue(files);
      teardown = initHotkeys();

      Mousetrap.trigger(nextFileKey);
      expect(files[2].selectFile).toHaveBeenCalled();

      // Backward steps from the navigation cursor, returning to the file
      // the forward press started from.
      Mousetrap.trigger(prevFileKey);
      expect(files[1].selectFile).toHaveBeenCalled();
    });
  });

  describe('commit navigation', () => {
    const NEXT_COMMIT_ID = 'abc123';
    const PREV_COMMIT_ID = 'def456';

    it.each`
      direction     | commitId          | commitField
      ${'next'}     | ${NEXT_COMMIT_ID} | ${'next_commit_id'}
      ${'previous'} | ${PREV_COMMIT_ID} | ${'prev_commit_id'}
    `('navigates to $direction commit via visitUrl', ({ direction, commitId, commitField }) => {
      useMergeRequestVersions().setCommit({ [commitField]: commitId });

      navigateCommit(direction);

      expect(visitUrl).toHaveBeenCalledWith(expect.stringContaining(`commit_id=${commitId}`));
    });

    it('does nothing when no commit is set', () => {
      navigateCommit('next');

      expect(visitUrl).not.toHaveBeenCalled();
    });

    it('does nothing when the neighbor commit id is absent', () => {
      useMergeRequestVersions().setCommit({ next_commit_id: null, prev_commit_id: null });

      navigateCommit('next');
      navigateCommit('previous');

      expect(visitUrl).not.toHaveBeenCalled();
    });

    it('binds to Mousetrap keybindings', () => {
      useMergeRequestVersions().setCommit({
        next_commit_id: NEXT_COMMIT_ID,
        prev_commit_id: PREV_COMMIT_ID,
      });
      teardown = initHotkeys();

      Mousetrap.trigger(keysFor(MR_COMMITS_NEXT_COMMIT)[0]);

      expect(visitUrl).toHaveBeenCalledWith(expect.stringContaining(`commit_id=${NEXT_COMMIT_ID}`));
    });
  });

  describe('toggleFileReview', () => {
    const CODE_REVIEW_ID = 'review-123';

    const makeMockFile = ({ isViewed = false, hasCheckbox = true } = {}) => {
      const diffElement = document.createElement('div');

      let checkbox = null;
      if (hasCheckbox) {
        checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.dataset.viewedCheckbox = '';
        checkbox.checked = isViewed;
        diffElement.appendChild(checkbox);
      }

      return {
        file: {
          data: { codeReviewId: CODE_REVIEW_ID },
          diffElement,
          trigger: jest.fn(),
          selectFile: jest.fn(),
        },
        checkbox,
      };
    };

    it('marks an unreviewed file as reviewed', () => {
      const { file, checkbox } = makeMockFile({ isViewed: false });

      toggleFileReview(file);

      expect(useCodeReview().reviewedIds[CODE_REVIEW_ID]).toBe(true);
      expect(checkbox.checked).toBe(true);
      expect(Object.hasOwn(file.diffElement.dataset, 'viewed')).toBe(true);
      expect(file.trigger).toHaveBeenCalledWith(COLLAPSE_FILE_BY_USER);
    });

    it('keeps the collapsed file in view when marking as reviewed', () => {
      const { file } = makeMockFile({ isViewed: false });

      toggleFileReview(file);

      expect(file.selectFile).toHaveBeenCalled();
    });

    it('does not scroll when marking as unreviewed', () => {
      const { file } = makeMockFile({ isViewed: true });
      useCodeReview().setReviewed(CODE_REVIEW_ID, true);

      toggleFileReview(file);

      expect(file.selectFile).not.toHaveBeenCalled();
    });

    it('marks a reviewed file as unreviewed', () => {
      const { file, checkbox } = makeMockFile({ isViewed: true });
      useCodeReview().setReviewed(CODE_REVIEW_ID, true);

      toggleFileReview(file);

      expect(useCodeReview().reviewedIds[CODE_REVIEW_ID]).toBe(false);
      expect(checkbox.checked).toBe(false);
      expect(Object.hasOwn(file.diffElement.dataset, 'viewed')).toBe(false);
      expect(file.trigger).toHaveBeenCalledWith(EXPAND_FILE);
    });

    it('works when the checkbox is not present', () => {
      const { file } = makeMockFile({ hasCheckbox: false });

      toggleFileReview(file);

      expect(useCodeReview().reviewedIds[CODE_REVIEW_ID]).toBe(true);
      expect(file.trigger).toHaveBeenCalledWith(COLLAPSE_FILE_BY_USER);
    });

    it('does nothing when file is null', () => {
      expect(() => toggleFileReview(null)).not.toThrow();
    });

    it('does nothing when file has no codeReviewId', () => {
      const file = {
        data: {},
        diffElement: document.createElement('div'),
        trigger: jest.fn(),
      };

      toggleFileReview(file);

      expect(file.trigger).not.toHaveBeenCalled();
    });

    it('binds to Mousetrap keybindings and uses tracked file', () => {
      const { file } = makeMockFile();
      useDiffsView().singleFileMode = true;
      jest.spyOn(DiffFile, 'getAll').mockReturnValue([file]);
      teardown = initHotkeys();

      Mousetrap.trigger(keysFor(MR_TOGGLE_REVIEW)[0]);

      expect(useCodeReview().reviewedIds[CODE_REVIEW_ID]).toBe(true);
    });
  });

  describe('toggleDiffViewType', () => {
    let updateViewType;

    beforeEach(() => {
      updateViewType = jest.spyOn(useDiffsView(), 'updateViewType').mockImplementation(() => {});
    });

    it('switches from inline to parallel view', () => {
      useDiffsView().viewType = INLINE_DIFF_VIEW_TYPE;

      toggleDiffViewType();

      expect(updateViewType).toHaveBeenCalledWith(PARALLEL_DIFF_VIEW_TYPE);
    });

    it('switches from parallel to inline view', () => {
      useDiffsView().viewType = PARALLEL_DIFF_VIEW_TYPE;

      toggleDiffViewType();

      expect(updateViewType).toHaveBeenCalledWith(INLINE_DIFF_VIEW_TYPE);
    });

    it('binds to Mousetrap keybindings', () => {
      useDiffsView().viewType = INLINE_DIFF_VIEW_TYPE;
      teardown = initHotkeys();

      Mousetrap.trigger(keysFor(MR_TOGGLE_DIFF_VIEW_TYPE)[0]);

      expect(updateViewType).toHaveBeenCalledWith(PARALLEL_DIFF_VIEW_TYPE);
    });
  });

  describe('quoteReply', () => {
    let container;

    const selectWithin = (node) => {
      const range = document.createRange();
      range.selectNodeContents(node);
      const selection = window.getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
    };

    beforeEach(() => {
      container = document.createElement('div');
      container.classList.add('js-discussion-container');
      container.textContent = 'a comment';
      document.body.appendChild(container);
    });

    afterEach(() => {
      window.getSelection().removeAllRanges();
      container.remove();
    });

    it('dispatches quoteReply on the discussion container closest to the selection', () => {
      const listener = jest.fn();
      container.addEventListener('quoteReply', listener);
      selectWithin(container);

      quoteReply();

      expect(listener).toHaveBeenCalledTimes(1);
    });

    it('does nothing when there is no selection', () => {
      const listener = jest.fn();
      container.addEventListener('quoteReply', listener);

      expect(() => quoteReply()).not.toThrow();
      expect(listener).not.toHaveBeenCalled();
    });

    it('does nothing when the selection is outside a discussion container', () => {
      const listener = jest.fn();
      container.addEventListener('quoteReply', listener);

      const outside = document.createElement('p');
      outside.textContent = 'unrelated text';
      document.body.appendChild(outside);
      selectWithin(outside);

      quoteReply();

      expect(listener).not.toHaveBeenCalled();
      outside.remove();
    });

    it('binds to Mousetrap keybindings', () => {
      const listener = jest.fn();
      container.addEventListener('quoteReply', listener);
      selectWithin(container);
      teardown = initHotkeys();

      Mousetrap.trigger(keysFor(ISSUABLE_COMMENT_OR_REPLY)[0]);

      expect(listener).toHaveBeenCalledTimes(1);
    });
  });

  describe('when merge request shortcuts are disabled', () => {
    let container;

    beforeEach(() => {
      teardown = initHotkeys({ mergeRequestShortcuts: false });
    });

    afterEach(() => {
      window.getSelection().removeAllRanges();
      container?.remove();
      container = null;
    });

    it('does not register the next commit shortcut', () => {
      useMergeRequestVersions().setCommit({ next_commit_id: 'abc123' });

      Mousetrap.trigger(keysFor(MR_COMMITS_NEXT_COMMIT)[0]);

      expect(visitUrl).not.toHaveBeenCalled();
    });

    it('does not register the previous commit shortcut', () => {
      useMergeRequestVersions().setCommit({ prev_commit_id: 'def456' });

      Mousetrap.trigger(keysFor(MR_COMMITS_PREVIOUS_COMMIT)[0]);

      expect(visitUrl).not.toHaveBeenCalled();
    });

    it('does not register the toggle review shortcut', () => {
      const file = {
        data: { codeReviewId: 'review-123' },
        diffElement: document.createElement('div'),
        trigger: jest.fn(),
      };
      jest.spyOn(DiffFile, 'getAll').mockReturnValue([file]);

      Mousetrap.trigger(keysFor(MR_TOGGLE_REVIEW)[0]);

      expect(file.trigger).not.toHaveBeenCalled();
    });

    it('still registers file navigation', () => {
      const files = makeFilesAt([
        [0, 700],
        [700, 800],
      ]);
      jest.spyOn(DiffFile, 'getAll').mockReturnValue(files);

      Mousetrap.trigger(keysFor(MR_NEXT_FILE_IN_DIFF)[0]);

      expect(files[1].selectFile).toHaveBeenCalled();
    });

    it('still registers backward file navigation', () => {
      const files = makeFilesAt([
        [-500, 100],
        [100, 800],
      ]);
      jest.spyOn(DiffFile, 'getAll').mockReturnValue(files);

      Mousetrap.trigger(keysFor(MR_PREVIOUS_FILE_IN_DIFF)[0]);

      expect(files[0].selectFile).toHaveBeenCalled();
    });

    it('still registers quote reply', () => {
      container = document.createElement('div');
      container.classList.add('js-discussion-container');
      container.textContent = 'a comment';
      document.body.appendChild(container);
      const listener = jest.fn();
      container.addEventListener('quoteReply', listener);
      const range = document.createRange();
      range.selectNodeContents(container);
      window.getSelection().addRange(range);

      Mousetrap.trigger(keysFor(ISSUABLE_COMMENT_OR_REPLY)[0]);

      expect(listener).toHaveBeenCalledTimes(1);
    });

    it('still registers the diff view type toggle', () => {
      const updateViewType = jest
        .spyOn(useDiffsView(), 'updateViewType')
        .mockImplementation(() => {});
      useDiffsView().viewType = INLINE_DIFF_VIEW_TYPE;

      Mousetrap.trigger(keysFor(MR_TOGGLE_DIFF_VIEW_TYPE)[0]);

      expect(updateViewType).toHaveBeenCalledWith(PARALLEL_DIFF_VIEW_TYPE);
    });
  });

  describe('teardown', () => {
    it('unbinds all hotkeys on teardown', () => {
      const files = [{ selectFile: jest.fn() }, { selectFile: jest.fn() }];
      jest.spyOn(DiffFile, 'getAll').mockReturnValue(files);

      teardown = initHotkeys();
      teardown();
      teardown = null;

      Mousetrap.trigger(keysFor(MR_NEXT_FILE_IN_DIFF)[0]);

      expect(files[0].selectFile).not.toHaveBeenCalled();
      expect(files[1].selectFile).not.toHaveBeenCalled();
    });
  });
});
