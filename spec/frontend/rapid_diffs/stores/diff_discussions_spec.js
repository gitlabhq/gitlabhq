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
        line_range: lineRange,
      });
      expect(result).toBe(undefined);
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

  describe('replyToLineDiscussion', () => {
    const defaultPosition = {
      oldPath: 'old/file.js',
      newPath: 'new/file.js',
      oldLine: 10,
      newLine: 20,
    };

    it.each`
      oldLine                    | newLine
      ${null}                    | ${defaultPosition.newLine}
      ${defaultPosition.oldLine} | ${null}
    `(
      'starts replying if an existing discussion is found at the position',
      ({ oldLine, newLine }) => {
        const testPosition = { ...defaultPosition, oldLine, newLine };
        const existingDiscussion = {
          id: 'existing-id',
          diff_discussion: true,
          isForm: false,
          repliesExpanded: false,
          isReplying: false,
          position: {
            old_path: defaultPosition.oldPath,
            new_path: defaultPosition.newPath,
            old_line: oldLine,
            new_line: newLine,
          },
        };
        useDiscussions().discussions = [existingDiscussion];

        const result = useDiffDiscussions().replyToLineDiscussion(testPosition);

        expect(existingDiscussion.repliesExpanded).toBe(true);
        expect(existingDiscussion.isReplying).toBe(true);
        expect(result).toBe(existingDiscussion.id);
      },
    );

    it('shows hidden discussions when replying', () => {
      useDiscussions().discussions = [
        {
          id: 'hidden',
          diff_discussion: true,
          hidden: true,
          repliesExpanded: false,
          isReplying: false,
          position: {
            old_path: defaultPosition.oldPath,
            new_path: defaultPosition.newPath,
            old_line: defaultPosition.oldLine,
            new_line: defaultPosition.newLine,
          },
        },
      ];
      useDiffDiscussions().replyToLineDiscussion(defaultPosition);
      expect(useDiscussions().discussions[0].hidden).toBe(false);
    });

    it('returns undefined if no existing discussion found', () => {
      const result = useDiffDiscussions().replyToLineDiscussion(defaultPosition);
      expect(result).toBeUndefined();
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

  describe('findDiscussionsForPosition', () => {
    const position = {
      oldPath: 'file1.js',
      newPath: 'file2.js',
      oldLine: 5,
      newLine: 10,
    };
    const matchingDiscussion = {
      id: 'match',
      isForm: false,
      diff_discussion: true,
      position: {
        old_path: position.oldPath,
        new_path: position.newPath,
        old_line: position.oldLine,
        new_line: position.newLine,
      },
    };

    it('returns matching discussions', () => {
      useDiscussions().discussions = [
        matchingDiscussion,
        { ...matchingDiscussion, id: 'match2' },
        { ...matchingDiscussion, diff_discussion: false, id: 'notmatch2' },
        {
          ...matchingDiscussion,
          id: 'notmatch3',
          position: { ...matchingDiscussion.position, old_path: 'other.js' },
        },
        {
          ...matchingDiscussion,
          id: 'notmatch4',
          position: { ...matchingDiscussion.position, old_line: 6 },
        },
      ];

      const found = useDiffDiscussions().findDiscussionsForPosition(position);

      expect(found).toHaveLength(2);
      expect(found.map((d) => d.id)).toEqual(['match', 'match2']);
    });

    it('returns an empty array if no discussions match', () => {
      useDiscussions().discussions = [
        { ...matchingDiscussion, diff_discussion: false, id: 'notmatch2' },
      ];

      const found = useDiffDiscussions().findDiscussionsForPosition(position);

      expect(found).toHaveLength(0);
    });

    it('includes form discussions in results', () => {
      const formDiscussion = { ...matchingDiscussion, isForm: true, id: 'form1' };
      useDiscussions().discussions = [matchingDiscussion];
      useDiffDiscussions().discussionForms = [formDiscussion];

      const found = useDiffDiscussions().findDiscussionsForPosition(position);

      expect(found).toHaveLength(2);
      expect(found.map((d) => d.id)).toEqual(['match', 'form1']);
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

  describe('findVisibleDiscussionsForFile', () => {
    beforeEach(() => {
      useDiscussions().setInitialDiscussions([
        {
          id: '1',
          diff_discussion: true,
          notes: [],
          position: { old_path: 'file1.js', new_path: 'file1.js' },
        },
        {
          id: '2',
          diff_discussion: true,
          notes: [],
          position: { old_path: 'file1.js', new_path: 'file1.js' },
          hidden: true,
        },
        {
          id: '3',
          diff_discussion: true,
          notes: [],
          position: { old_path: 'file2.js', new_path: 'file2.js' },
        },
      ]);
      useDiffDiscussions().discussionForms = [
        {
          id: '4',
          isForm: true,
          diff_discussion: true,
          position: { old_path: 'file1.js', new_path: 'file1.js' },
        },
      ];
    });

    it('returns visible discussions matching the file paths including forms', () => {
      const discussions = useDiffDiscussions().findVisibleDiscussionsForFile({
        oldPath: 'file1.js',
        newPath: 'file1.js',
      });

      expect(discussions).toHaveLength(2);
      expect(discussions.map((d) => d.id)).toEqual(['1', '4']);
    });

    it('excludes hidden discussions', () => {
      const discussions = useDiffDiscussions().findVisibleDiscussionsForFile({
        oldPath: 'file1.js',
        newPath: 'file1.js',
      });

      expect(discussions.every((d) => !d.hidden)).toBe(true);
    });

    it('returns empty array when no discussions match', () => {
      const discussions = useDiffDiscussions().findVisibleDiscussionsForFile({
        oldPath: 'nonexistent.js',
        newPath: 'nonexistent.js',
      });

      expect(discussions).toHaveLength(0);
    });
  });

  describe('findFileDiscussionsForFile', () => {
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

      const discussions = useDiffDiscussions().findFileDiscussionsForFile(filePaths);

      expect(discussions).toHaveLength(1);
      expect(discussions[0].id).toBe('1');
    });

    it('returns file discussion forms', () => {
      useDiffDiscussions().addNewFileDiscussionForm(filePaths);

      const discussions = useDiffDiscussions().findFileDiscussionsForFile(filePaths);

      expect(discussions).toHaveLength(1);
      expect(discussions[0].isForm).toBe(true);
    });

    it('excludes hidden file discussions', () => {
      useDiscussions().setInitialDiscussions([
        {
          id: '1',
          diff_discussion: true,
          notes: [],
          hidden: true,
          position: { old_path: 'file1.js', new_path: 'file1.js', position_type: 'file' },
        },
      ]);

      expect(useDiffDiscussions().findFileDiscussionsForFile(filePaths)).toHaveLength(0);
    });
  });

  describe('findVisibleDiscussionsForFile (excludes file discussions)', () => {
    it('excludes discussions with position_type file', () => {
      useDiscussions().setInitialDiscussions([
        {
          id: 'line',
          diff_discussion: true,
          notes: [],
          position: { old_path: 'file1.js', new_path: 'file1.js', old_line: 1, new_line: null },
        },
        {
          id: 'file',
          diff_discussion: true,
          notes: [],
          position: { old_path: 'file1.js', new_path: 'file1.js', position_type: 'file' },
        },
      ]);

      const discussions = useDiffDiscussions().findVisibleDiscussionsForFile({
        oldPath: 'file1.js',
        newPath: 'file1.js',
      });

      expect(discussions).toHaveLength(1);
      expect(discussions[0].id).toBe('line');
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

  describe('getImageDiscussions', () => {
    it('returns discussions with matching image position type', () => {
      useDiscussions().discussions = [
        {
          id: 1,
          notes: [{ note: 'text note' }],
        },
        {
          id: 2,
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
      expect(useDiffDiscussions().getImageDiscussions('old.png', 'new.png')).toMatchObject([
        useDiscussions().discussions[1],
      ]);
    });
  });
});
