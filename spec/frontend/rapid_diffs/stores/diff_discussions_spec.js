import { createTestingPinia } from '@pinia/testing';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import { useDiscussions } from '~/notes/store/discussions';

describe('diffDiscussions store', () => {
  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    window.gon.current_user_id = 1;
  });

  it.each([
    'setInitialDiscussions',
    'replaceDiscussion',
    'toggleDiscussionReplies',
    'expandDiscussionReplies',
    'startReplying',
    'stopReplying',
    'addNote',
    'updateNote',
    'updateNoteTextById',
    'editNote',
    'deleteNote',
    'addDiscussion',
    'deleteDiscussion',
    'setEditingMode',
    'requestLastNoteEditing',
    'toggleAward',
    'updateDiscussion',
    'collapseDiscussion',
    'expandDiscussion',
    'toggleAllDiffDiscussions',
  ])('exposes %s from base store', (action) => {
    expect(useDiffDiscussions()[action]).toEqual(expect.any(Function));
  });

  describe('discussionsWithForms', () => {
    it('combines base discussions and discussion forms', () => {
      useDiscussions().discussions = [{ id: 'd1' }];
      useDiffDiscussions().discussionForms = [{ id: 'f1', isForm: true }];
      expect(useDiffDiscussions().discussionsWithForms).toHaveLength(2);
      expect(useDiffDiscussions().discussionsWithForms[0].id).toBe('d1');
      expect(useDiffDiscussions().discussionsWithForms[1].id).toBe('f1');
    });
  });

  describe('addNewLineDiscussionForm', () => {
    const lineRange = {
      start: { old_line: 10, new_line: 20, type: null },
      end: { old_line: 10, new_line: 20, type: null },
    };
    const defaultPosition = { oldPath: 'old/file.js', newPath: 'new/file.js', lineRange };
    const formId = 'old/file.js-new/file.js-10-20';

    it('returns id if form already exists', () => {
      useDiffDiscussions().discussionForms = [{ id: formId }];
      expect(useDiffDiscussions().addNewLineDiscussionForm(defaultPosition)).toBe(formId);
    });

    it('adds a new discussion form if none exists', () => {
      const result = useDiffDiscussions().addNewLineDiscussionForm(defaultPosition);

      const newDiscussion = useDiffDiscussions().discussionForms[0];
      expect(useDiffDiscussions().discussionForms).toHaveLength(1);
      expect(newDiscussion.id).toBe(formId);
      expect(newDiscussion.diff_discussion).toBe(true);
      expect(newDiscussion.isForm).toBe(true);
      expect(newDiscussion.noteBody).toBe('');
      expect(newDiscussion.shouldFocus).toBe(true);
      expect(newDiscussion.position).toStrictEqual({
        old_path: defaultPosition.oldPath,
        new_path: defaultPosition.newPath,
        old_line: 10,
        new_line: 20,
        position_type: 'text',
        line_range: lineRange,
      });
      expect(result).toBe(undefined);
    });

    it('stores lineChange and lineCode on the form', () => {
      const lineChange = { change: 'added', position: 'new' };
      const lineCode = 'abc_10_20';
      useDiffDiscussions().addNewLineDiscussionForm({ ...defaultPosition, lineChange, lineCode });

      const newDiscussion = useDiffDiscussions().discussionForms[0];
      expect(newDiscussion.lineChange).toStrictEqual(lineChange);
      expect(newDiscussion.lineCode).toBe(lineCode);
    });

    it('spreads extraOptions onto the form', () => {
      const lines = ['line one', 'line two'];
      useDiffDiscussions().addNewLineDiscussionForm({
        ...defaultPosition,
        extraOptions: { lines, canSuggest: true },
      });
      const form = useDiffDiscussions().discussionForms[0];
      expect(form.lines).toStrictEqual(lines);
      expect(form.canSuggest).toBe(true);
    });

    it('shows hidden discussions at the same position', () => {
      useDiffDiscussions().setInitialDiscussions([
        {
          id: 'same-position',
          diff_discussion: true,
          hidden: true,
          position: {
            old_path: defaultPosition.oldPath,
            new_path: defaultPosition.newPath,
            old_line: 10,
            new_line: 20,
          },
          notes: [],
        },
        {
          id: 'other-position',
          diff_discussion: true,
          hidden: true,
          position: {
            old_path: defaultPosition.oldPath,
            new_path: defaultPosition.newPath,
            old_line: 99,
            new_line: null,
          },
          notes: [],
        },
      ]);
      useDiffDiscussions().addNewLineDiscussionForm(defaultPosition);
      expect(useDiscussions().discussions[0].hidden).toBe(false);
      expect(useDiscussions().discussions[1].hidden).toBe(true);
    });
  });

  describe('replaceDiscussionForm', () => {
    it('removes the form and adds the new discussion to the base store', () => {
      const form = { id: 'form-1', isForm: true };
      useDiffDiscussions().discussionForms = [form];

      useDiffDiscussions().replaceDiscussionForm(form, { id: 'new-disc', notes: [{ id: 'n1' }] });

      expect(useDiffDiscussions().discussionForms).toHaveLength(0);
      expect(useDiscussions().discussions[0].id).toBe('new-disc');
    });
  });

  describe('removeNewLineDiscussionForm', () => {
    it('removes the discussion form from the list', () => {
      const discussionToHide = { id: 'form-1', isForm: true };
      const otherDiscussion = { id: 'form-2', isForm: true };
      useDiffDiscussions().discussionForms = [discussionToHide, otherDiscussion];

      useDiffDiscussions().removeNewLineDiscussionForm(discussionToHide);

      expect(useDiffDiscussions().discussionForms).toHaveLength(1);
      expect(useDiffDiscussions().discussionForms[0].id).toBe('form-2');
    });
  });

  describe('setDiscussionFormText', () => {
    it('sets the noteBody for the discussion form', () => {
      const discussion = { id: 'form-1', noteBody: 'old text' };
      const newText = 'new text';

      useDiffDiscussions().setDiscussionFormText(discussion, newText);

      expect(discussion.noteBody).toBe(newText);
    });
  });

  describe('setNewLineDiscussionFormAutofocus', () => {
    it('sets the shouldFocus property for the discussion form', () => {
      const discussion = { id: 'form-1', shouldFocus: true };
      useDiffDiscussions().setNewLineDiscussionFormAutofocus(discussion, false);

      expect(discussion.shouldFocus).toBe(false);
    });
  });

  describe('collapseDiscussion', () => {
    it('sets hidden to true', () => {
      const discussion = { id: '1', hidden: false };
      useDiffDiscussions().collapseDiscussion(discussion);
      expect(discussion.hidden).toBe(true);
    });
  });

  describe('expandDiscussion', () => {
    it('sets hidden to false', () => {
      const discussion = { id: '1', hidden: true };
      useDiffDiscussions().expandDiscussion(discussion);
      expect(discussion.hidden).toBe(false);
    });
  });

  describe('allDiffDiscussionsExpanded', () => {
    it('is true when there are no diff discussions', () => {
      useDiscussions().discussions = [];
      expect(useDiffDiscussions().allDiffDiscussionsExpanded).toBe(true);
    });

    it('is true when every diff discussion is not hidden', () => {
      useDiscussions().discussions = [
        { id: '1', diff_discussion: true, hidden: false },
        { id: '2', diff_discussion: true, hidden: false },
        { id: '3', diff_discussion: false, hidden: true },
      ];
      expect(useDiffDiscussions().allDiffDiscussionsExpanded).toBe(true);
    });

    it('is false when any diff discussion is hidden', () => {
      useDiscussions().discussions = [
        { id: '1', diff_discussion: true, hidden: false },
        { id: '2', diff_discussion: true, hidden: true },
      ];
      expect(useDiffDiscussions().allDiffDiscussionsExpanded).toBe(false);
    });

    it('ignores non-diff discussions when computing expanded state', () => {
      useDiscussions().discussions = [
        { id: '1', diff_discussion: true, hidden: false },
        { id: '2', diff_discussion: false, hidden: true },
      ];
      expect(useDiffDiscussions().allDiffDiscussionsExpanded).toBe(true);
    });
  });

  describe('toggleAllDiffDiscussions', () => {
    it('hides every diff discussion when all are currently expanded', () => {
      useDiscussions().discussions = [
        { id: '1', diff_discussion: true, hidden: false },
        { id: '2', diff_discussion: true, hidden: false },
      ];

      useDiffDiscussions().toggleAllDiffDiscussions();

      expect(useDiscussions().discussions[0].hidden).toBe(true);
      expect(useDiscussions().discussions[1].hidden).toBe(true);
    });

    it('shows every diff discussion when any is currently hidden', () => {
      useDiscussions().discussions = [
        { id: '1', diff_discussion: true, hidden: true },
        { id: '2', diff_discussion: true, hidden: false },
      ];

      useDiffDiscussions().toggleAllDiffDiscussions();

      expect(useDiscussions().discussions[0].hidden).toBe(false);
      expect(useDiscussions().discussions[1].hidden).toBe(false);
    });

    it('leaves non-diff discussions untouched', () => {
      useDiscussions().discussions = [
        { id: '1', diff_discussion: true, hidden: false },
        { id: '2', diff_discussion: false, hidden: false },
      ];

      useDiffDiscussions().toggleAllDiffDiscussions();

      expect(useDiscussions().discussions[1].hidden).toBe(false);
    });
  });

  describe('setFileDiscussionsHidden', () => {
    beforeEach(() => {
      useDiscussions().discussions = [
        {
          id: '1',
          diff_discussion: true,
          position: { old_path: 'file1.js', new_path: 'file1.js' },
        },
        {
          id: '2',
          diff_discussion: true,
          position: { old_path: 'file1.js', new_path: 'file1.js' },
        },
        {
          id: '3',
          diff_discussion: true,
          position: { old_path: 'file2.js', new_path: 'file2.js' },
        },
      ];
    });

    it('hides all discussions for a file when newState is true', () => {
      useDiffDiscussions().setFileDiscussionsHidden('file1.js', 'file1.js', true);

      expect(useDiscussions().discussions[0].hidden).toBe(true);
      expect(useDiscussions().discussions[1].hidden).toBe(true);
    });

    it('shows all discussions for a file when newState is false', () => {
      useDiffDiscussions().setFileDiscussionsHidden('file1.js', 'file1.js', true);
      useDiffDiscussions().setFileDiscussionsHidden('file1.js', 'file1.js', false);

      expect(useDiscussions().discussions[0].hidden).toBe(false);
      expect(useDiscussions().discussions[1].hidden).toBe(false);
    });
  });

  describe('setPositionDiscussionsHidden', () => {
    beforeEach(() => {
      useDiscussions().discussions = [
        {
          id: '1',
          diff_discussion: true,
          position: { old_path: 'file1.js', new_path: 'file1.js', old_line: 5, new_line: null },
        },
        {
          id: '2',
          diff_discussion: true,
          position: { old_path: 'file1.js', new_path: 'file1.js', old_line: 5, new_line: null },
        },
        {
          id: '3',
          diff_discussion: true,
          position: { old_path: 'file1.js', new_path: 'file1.js', old_line: 10, new_line: null },
        },
      ];
    });

    it('hides discussions at a specific position', () => {
      useDiffDiscussions().setPositionDiscussionsHidden(
        { oldPath: 'file1.js', newPath: 'file1.js', oldLine: 5, newLine: null },
        true,
      );

      expect(useDiscussions().discussions[0].hidden).toBe(true);
      expect(useDiscussions().discussions[1].hidden).toBe(true);
      expect(useDiscussions().discussions[2].hidden).toBeUndefined();
    });

    it('shows discussions at a specific position', () => {
      useDiffDiscussions().setPositionDiscussionsHidden(
        { oldPath: 'file1.js', newPath: 'file1.js', oldLine: 5, newLine: null },
        true,
      );
      useDiffDiscussions().setPositionDiscussionsHidden(
        { oldPath: 'file1.js', newPath: 'file1.js', oldLine: 5, newLine: null },
        false,
      );

      expect(useDiscussions().discussions[0].hidden).toBe(false);
      expect(useDiscussions().discussions[1].hidden).toBe(false);
    });
  });

  describe('findDiscussionsForFile', () => {
    beforeEach(() => {
      useDiscussions().discussions = [
        {
          id: '1',
          diff_discussion: true,
          position: { old_path: 'file1.js', new_path: 'file1.js' },
        },
        {
          id: '2',
          diff_discussion: true,
          position: { old_path: 'file2.js', new_path: 'file2.js' },
        },
      ];
      useDiffDiscussions().discussionForms = [
        {
          id: '3',
          isForm: true,
          diff_discussion: true,
          position: { old_path: 'file1.js', new_path: 'file1.js' },
        },
      ];
    });

    it('returns discussions matching the file paths', () => {
      const discussions = useDiffDiscussions().findDiscussionsForFile({
        oldPath: 'file1.js',
        newPath: 'file1.js',
      });

      expect(discussions).toHaveLength(1);
      expect(discussions[0].id).toBe('1');
    });

    it('excludes discussion forms', () => {
      const discussions = useDiffDiscussions().findDiscussionsForFile({
        oldPath: 'file1.js',
        newPath: 'file1.js',
      });

      expect(discussions.every((d) => !d.isForm)).toBe(true);
    });

    it('returns empty array when no discussions match', () => {
      const discussions = useDiffDiscussions().findDiscussionsForFile({
        oldPath: 'nonexistent.js',
        newPath: 'nonexistent.js',
      });

      expect(discussions).toHaveLength(0);
    });
  });

  describe('findAllDiscussionsForFile', () => {
    beforeEach(() => {
      useDiscussions().discussions = [
        {
          id: '1',
          diff_discussion: true,
          position: { old_path: 'file1.js', new_path: 'file1.js' },
        },
        {
          id: '2',
          diff_discussion: true,
          position: { old_path: 'file2.js', new_path: 'file2.js' },
        },
      ];
      useDiffDiscussions().discussionForms = [
        {
          id: '3',
          isForm: true,
          diff_discussion: true,
          position: { old_path: 'file1.js', new_path: 'file1.js' },
        },
      ];
    });

    it('returns all discussions matching the file paths including forms', () => {
      const discussions = useDiffDiscussions().findAllDiscussionsForFile({
        oldPath: 'file1.js',
        newPath: 'file1.js',
      });

      expect(discussions).toHaveLength(2);
      expect(discussions.map((d) => d.id)).toEqual(['1', '3']);
    });

    it('returns empty array when no discussions match', () => {
      const discussions = useDiffDiscussions().findAllDiscussionsForFile({
        oldPath: 'nonexistent.js',
        newPath: 'nonexistent.js',
      });

      expect(discussions).toHaveLength(0);
    });
  });

  describe('findLinePositionsForFile', () => {
    const filePaths = { oldPath: 'file1.js', newPath: 'file1.js' };

    it('returns only line positions, excluding file and image discussions', () => {
      useDiscussions().discussions = [
        {
          id: 'line',
          diff_discussion: true,
          position: {
            old_path: 'file1.js',
            new_path: 'file1.js',
            position_type: 'text',
            old_line: 1,
            new_line: 1,
          },
        },
        {
          id: 'file',
          diff_discussion: true,
          position: {
            old_path: 'file1.js',
            new_path: 'file1.js',
            position_type: 'file',
          },
        },
        {
          id: 'image',
          diff_discussion: true,
          position: {
            old_path: 'file1.js',
            new_path: 'file1.js',
            position_type: 'image',
          },
        },
      ];

      const positions = useDiffDiscussions().findLinePositionsForFile(filePaths);

      expect(positions).toHaveLength(1);
      expect(positions[0].old_line).toBe(1);
      expect(positions[0].new_line).toBe(1);
    });

    it('includes positions from line discussion forms', () => {
      useDiffDiscussions().addNewLineDiscussionForm({
        oldPath: 'file1.js',
        newPath: 'file1.js',
        lineRange: { start: { old_line: 1, new_line: 1 }, end: { old_line: 1, new_line: 1 } },
        lineChange: 'added',
        lineCode: 'abc',
      });

      const positions = useDiffDiscussions().findLinePositionsForFile(filePaths);

      expect(positions).toHaveLength(1);
      expect(positions[0].old_line).toBe(1);
    });

    it('excludes file discussion forms', () => {
      useDiffDiscussions().addNewFileDiscussionForm(filePaths);

      const positions = useDiffDiscussions().findLinePositionsForFile(filePaths);

      expect(positions).toHaveLength(0);
    });
  });

  describe('findLineDiscussionsForPosition', () => {
    const filePaths = { oldPath: 'file1.js', newPath: 'file1.js' };

    it('returns discussions matching the given position', () => {
      useDiscussions().discussions = [
        {
          id: 'match',
          diff_discussion: true,
          position: {
            old_path: 'file1.js',
            new_path: 'file1.js',
            position_type: 'text',
            old_line: 1,
            new_line: 1,
          },
        },
        {
          id: 'no-match',
          diff_discussion: true,
          position: {
            old_path: 'file1.js',
            new_path: 'file1.js',
            position_type: 'text',
            old_line: 5,
            new_line: 5,
          },
        },
      ];

      const discussions = useDiffDiscussions().findLineDiscussionsForPosition({
        ...filePaths,
        oldLine: 1,
        newLine: 1,
      });

      expect(discussions).toHaveLength(1);
      expect(discussions[0].id).toBe('match');
    });

    it('excludes file and image discussions', () => {
      useDiscussions().discussions = [
        {
          id: 'file',
          diff_discussion: true,
          position: {
            old_path: 'file1.js',
            new_path: 'file1.js',
            position_type: 'file',
          },
        },
      ];

      const discussions = useDiffDiscussions().findLineDiscussionsForPosition({
        ...filePaths,
        oldLine: null,
        newLine: null,
      });

      expect(discussions).toHaveLength(0);
    });
  });

  describe('findAllFileDiscussionsForFile', () => {
    const filePaths = { oldPath: 'file1.js', newPath: 'file1.js' };

    it('returns discussions with position_type file', () => {
      useDiscussions().setInitialDiscussions([
        {
          id: '1',
          diff_discussion: true,
          notes: [],
          position: { old_path: 'file1.js', new_path: 'file1.js', position_type: 'file' },
        },
        {
          id: '2',
          diff_discussion: true,
          notes: [],
          position: { old_path: 'file1.js', new_path: 'file1.js', old_line: 1, new_line: null },
        },
      ]);

      const discussions = useDiffDiscussions().findAllFileDiscussionsForFile(filePaths);

      expect(discussions).toHaveLength(1);
      expect(discussions[0].id).toBe('1');
    });

    it('returns file discussion forms', () => {
      useDiffDiscussions().addNewFileDiscussionForm(filePaths);

      const discussions = useDiffDiscussions().findAllFileDiscussionsForFile(filePaths);

      expect(discussions).toHaveLength(1);
      expect(discussions[0].isForm).toBe(true);
    });

    it('includes hidden file discussions', () => {
      useDiscussions().setInitialDiscussions([
        {
          id: '1',
          diff_discussion: true,
          notes: [],
          hidden: true,
          position: { old_path: 'file1.js', new_path: 'file1.js', position_type: 'file' },
        },
      ]);

      expect(useDiffDiscussions().findAllFileDiscussionsForFile(filePaths)).toHaveLength(1);
    });
  });

  describe('expandFileDiscussions', () => {
    const oldPath = 'file1.js';
    const newPath = 'file1.js';

    beforeEach(() => {
      useDiscussions().setInitialDiscussions([
        {
          id: 'file',
          diff_discussion: true,
          notes: [],
          hidden: true,
          position: { old_path: oldPath, new_path: newPath, position_type: 'file' },
        },
        {
          id: 'line',
          diff_discussion: true,
          notes: [],
          hidden: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 1, new_line: null },
        },
      ]);
    });

    it('sets hidden to false only for file-type discussions', () => {
      useDiffDiscussions().expandFileDiscussions(oldPath, newPath);

      const [fileDisc, lineDisc] = useDiscussions().discussions;
      expect(fileDisc.hidden).toBe(false);
      expect(lineDisc.hidden).toBe(true);
    });
  });

  describe('addNewFileDiscussionForm', () => {
    const filePaths = { oldPath: 'file1.js', newPath: 'file1.js' };
    const formId = 'file1.js-file1.js-file';

    it('returns id if form already exists', () => {
      useDiffDiscussions().discussionForms = [{ id: formId }];
      expect(useDiffDiscussions().addNewFileDiscussionForm(filePaths)).toBe(formId);
    });

    it('adds a new file discussion form if none exists', () => {
      const result = useDiffDiscussions().addNewFileDiscussionForm(filePaths);

      const newDiscussion = useDiffDiscussions().discussionForms[0];
      expect(useDiffDiscussions().discussionForms).toHaveLength(1);
      expect(newDiscussion.id).toBe(formId);
      expect(newDiscussion.diff_discussion).toBe(true);
      expect(newDiscussion.isForm).toBe(true);
      expect(newDiscussion.noteBody).toBe('');
      expect(newDiscussion.shouldFocus).toBe(true);
      expect(newDiscussion.position).toStrictEqual({
        position_type: 'file',
        old_path: filePaths.oldPath,
        new_path: filePaths.newPath,
        old_line: null,
        new_line: null,
      });
      expect(result).toBe(undefined);
    });
  });

  describe('removeNewFileDiscussionForm', () => {
    it('removes the file discussion form from the list', () => {
      const fileForm = { id: 'file-form', isForm: true };
      const otherForm = { id: 'other-form', isForm: true };
      useDiffDiscussions().discussionForms = [fileForm, otherForm];

      useDiffDiscussions().removeNewFileDiscussionForm(fileForm);

      expect(useDiffDiscussions().discussionForms).toHaveLength(1);
      expect(useDiffDiscussions().discussionForms[0].id).toBe('other-form');
    });
  });

  describe('findAllImageDiscussionsForFile', () => {
    it('returns discussions with matching image position type', () => {
      useDiscussions().discussions = [
        {
          id: 1,
          notes: [{ note: 'text note' }],
        },
        {
          id: 2,
          position: {
            position_type: 'image',
            old_path: 'old.png',
            new_path: 'new.png',
          },
          notes: [
            {
              position: {
                position_type: 'image',
                old_path: 'old.png',
                new_path: 'new.png',
              },
            },
          ],
        },
      ];
      expect(
        useDiffDiscussions().findAllImageDiscussionsForFile('old.png', 'new.png'),
      ).toMatchObject([useDiscussions().discussions[1]]);
    });
  });
});
