import { createTestingPinia } from '@pinia/testing';
import { Mousetrap } from '~/lib/mousetrap';
import {
  keysFor,
  MR_NEXT_FILE_IN_DIFF,
  MR_PREVIOUS_FILE_IN_DIFF,
  MR_COMMITS_NEXT_COMMIT,
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
    window.gon = {};
  });

  describe('createFileNavigation', () => {
    const makeFile = (id) => ({ selectFile: jest.fn(), id });

    it('starts at index 0', () => {
      const nav = createFileNavigation();
      jest.spyOn(DiffFile, 'getAll').mockReturnValue([makeFile('a'), makeFile('b')]);

      expect(nav.getCurrentFile().id).toBe('a');
    });

    it('advances forward through files', () => {
      const nav = createFileNavigation();
      const files = [makeFile('a'), makeFile('b'), makeFile('c')];
      jest.spyOn(DiffFile, 'getAll').mockReturnValue(files);

      nav.jumpToFile(+1);

      expect(files[1].selectFile).toHaveBeenCalled();
      expect(nav.getCurrentFile().id).toBe('b');
    });

    it('advances backward through files', () => {
      const nav = createFileNavigation();
      const files = [makeFile('a'), makeFile('b'), makeFile('c')];
      jest.spyOn(DiffFile, 'getAll').mockReturnValue(files);

      nav.jumpToFile(+1);
      nav.jumpToFile(+1);
      nav.jumpToFile(-1);

      expect(files[1].selectFile).toHaveBeenCalledTimes(2);
      expect(nav.getCurrentFile().id).toBe('b');
    });

    it('does not navigate past the last file', () => {
      const nav = createFileNavigation();
      const files = [makeFile('a')];
      jest.spyOn(DiffFile, 'getAll').mockReturnValue(files);

      nav.jumpToFile(+1);

      expect(files[0].selectFile).not.toHaveBeenCalled();
    });

    it('does not navigate before the first file', () => {
      const nav = createFileNavigation();
      const files = [makeFile('a')];
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

    it('clamps the index when files are removed', () => {
      const nav = createFileNavigation();
      const threeFiles = [makeFile('a'), makeFile('b'), makeFile('c')];
      jest.spyOn(DiffFile, 'getAll').mockReturnValue(threeFiles);

      nav.jumpToFile(+1);
      nav.jumpToFile(+1);

      const twoFiles = [makeFile('a'), makeFile('b')];
      jest.spyOn(DiffFile, 'getAll').mockReturnValue(twoFiles);

      expect(nav.getCurrentFile().id).toBe('b');
    });
  });

  describe('file navigation keybindings', () => {
    const nextFileKey = keysFor(MR_NEXT_FILE_IN_DIFF)[0];
    const prevFileKey = keysFor(MR_PREVIOUS_FILE_IN_DIFF)[0];

    it('navigates forward and backward through files', () => {
      const files = [
        { selectFile: jest.fn(), id: 'a' },
        { selectFile: jest.fn(), id: 'b' },
        { selectFile: jest.fn(), id: 'c' },
      ];
      jest.spyOn(DiffFile, 'getAll').mockReturnValue(files);
      teardown = initHotkeys();

      Mousetrap.trigger(nextFileKey);
      expect(files[1].selectFile).toHaveBeenCalled();

      Mousetrap.trigger(nextFileKey);
      expect(files[2].selectFile).toHaveBeenCalled();

      Mousetrap.trigger(prevFileKey);
      expect(files[1].selectFile).toHaveBeenCalledTimes(2);
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
