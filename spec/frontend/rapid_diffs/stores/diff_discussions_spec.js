import { createPinia, setActivePinia } from 'pinia';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';

describe('diffDiscussions store', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    window.gon.current_user_id = 1;
  });

  describe('setInitialDiscussions', () => {
    it('sets transformed initial discussions', () => {
      const discussions = [{ id: 'abc', notes: [{ id: 'bcd' }] }];
      useDiffDiscussions().setInitialDiscussions(discussions);
      expect(useDiffDiscussions().discussions[0].repliesExpanded).toBe(true);
      expect(useDiffDiscussions().discussions[0].notes[0].isEditing).toBe(false);
      expect(useDiffDiscussions().discussions[0].notes[0].editedNote).toBeNull();
      expect(useDiffDiscussions().discussions[0].hidden).toBe(false);
    });
  });

  describe('replaceDiscussion', () => {
    it('replaces an old discussion with a new, transformed discussion', () => {
      const oldDiscussion = { id: 'old' };
      const newDiscussion = { id: 'new', notes: [{ id: 'note2' }] };
      useDiffDiscussions().discussions = [oldDiscussion, { id: 'other' }];

      useDiffDiscussions().replaceDiscussion(oldDiscussion, newDiscussion);

      const store = useDiffDiscussions();
      expect(store.discussions).toHaveLength(2);
      expect(store.discussions[0].id).toBe('new');
      expect(store.discussions[0].repliesExpanded).toBe(true);
      expect(store.discussions[0].notes[0].isEditing).toBe(false);
      expect(store.discussions[1].id).toBe('other');
    });
  });

  describe('toggleDiscussionReplies', () => {
    it('toggles', () => {
      useDiffDiscussions().discussions = [{ id: 'abc', repliesExpanded: true }];
      useDiffDiscussions().toggleDiscussionReplies(useDiffDiscussions().discussions[0]);
      expect(useDiffDiscussions().discussions[0].repliesExpanded).toBe(false);
    });
  });

  describe('expandDiscussionReplies', () => {
    it('expands', () => {
      useDiffDiscussions().discussions = [{ id: 'abc', repliesExpanded: false }];
      useDiffDiscussions().expandDiscussionReplies(useDiffDiscussions().discussions[0]);
      expect(useDiffDiscussions().discussions[0].repliesExpanded).toBe(true);
    });
  });

  describe('startReplying', () => {
    it('expands and sets isReplying to true', () => {
      useDiffDiscussions().discussions = [{ id: 'abc', repliesExpanded: false, isReplying: false }];
      useDiffDiscussions().startReplying(useDiffDiscussions().discussions[0]);
      expect(useDiffDiscussions().discussions[0].repliesExpanded).toBe(true);
      expect(useDiffDiscussions().discussions[0].isReplying).toBe(true);
    });
  });

  describe('stopReplying', () => {
    it('sets isReplying to false', () => {
      useDiffDiscussions().discussions = [{ id: 'abc', isReplying: true }];
      useDiffDiscussions().stopReplying(useDiffDiscussions().discussions[0]);
      expect(useDiffDiscussions().discussions[0].isReplying).toBe(false);
    });
  });

  describe('addNote', () => {
    it('adds a note', () => {
      const note = { id: 'bar', discussion_id: 'abc' };
      useDiffDiscussions().discussions = [
        { id: 'abc', notes: [{ id: 'foo', discussion_id: 'abc' }] },
      ];
      useDiffDiscussions().addNote(note);
      expect(useDiffDiscussions().discussions[0].notes[1]).toStrictEqual(note);
    });

    it('does not add a note when it exists', () => {
      const note = { id: 'foo', discussion_id: 'abc' };
      useDiffDiscussions().discussions = [
        { id: 'abc', notes: [{ id: 'foo', discussion_id: 'abc' }] },
      ];
      useDiffDiscussions().addNote(note);
      expect(useDiffDiscussions().discussions[0].notes).toHaveLength(1);
    });
  });

  describe('updateNote', () => {
    it('updates existing note', () => {
      useDiffDiscussions().discussions = [
        { id: 'abc', notes: [{ id: 'foo', discussion_id: 'abc', note: 'Hello!' }] },
      ];
      useDiffDiscussions().updateNote({ id: 'foo', discussion_id: 'abc', note: 'Hello world!' });
      expect(useDiffDiscussions().discussions[0].notes[0].note).toBe('Hello world!');
    });
  });

  describe('editNote', () => {
    it('updates existing note', () => {
      const value = 'edit';
      const note = { id: 'foo', discussion_id: 'abc', note: 'Hello!' };
      useDiffDiscussions().discussions = [{ id: 'abc', notes: [note] }];
      useDiffDiscussions().editNote({ note, value });
      expect(useDiffDiscussions().discussions[0].notes[0].note).toBe('Hello!');
      expect(useDiffDiscussions().discussions[0].notes[0].editedNote).toBe(value);
    });
  });

  describe('deleteNote', () => {
    it('deletes existing note', () => {
      const note = { id: 'foo', discussion_id: 'abc', note: 'Hello!' };
      const remainingNote = {};
      useDiffDiscussions().discussions = [{ id: 'abc', notes: [note, remainingNote] }];
      useDiffDiscussions().deleteNote(note);
      expect(useDiffDiscussions().discussions[0].notes).toHaveLength(1);
      expect(useDiffDiscussions().discussions[0].notes[0]).toStrictEqual(remainingNote);
    });

    it('deletes discussions when no notes left', () => {
      const note = { id: 'foo', discussion_id: 'abc', note: 'Hello!' };
      useDiffDiscussions().discussions = [{ id: 'abc', notes: [note] }];
      useDiffDiscussions().deleteNote(note);
      expect(useDiffDiscussions().discussions).toHaveLength(0);
    });
  });

  describe('deleteDiscussion', () => {
    it('deletes existing discussion', () => {
      const discussion = {
        id: 'foo',
        notes: [{ id: 'foo', discussion_id: 'abc', note: 'Hello!' }],
      };
      useDiffDiscussions().discussions = [discussion];
      useDiffDiscussions().deleteDiscussion(discussion);
      expect(useDiffDiscussions().discussions).toHaveLength(0);
    });
  });

  describe('setEditingMode', () => {
    it('sets editing mode', () => {
      const note = { id: 'foo', isEditing: false };
      const discussion = { id: 'efg', notes: [note] };
      useDiffDiscussions().discussions = [discussion];
      useDiffDiscussions().setEditingMode(useDiffDiscussions().discussions[0].notes[0], true);
      expect(useDiffDiscussions().discussions[0].notes[0].isEditing).toBe(true);
    });
  });

  describe('requestLastNoteEditing', () => {
    const createOwnedNote = (canEdit = true) => ({
      id: Math.random(),
      author: { id: window.gon.current_user_id },
      current_user: { can_edit: canEdit },
      isEditing: false,
    });
    const createForeignNote = (canEdit = true) => ({
      id: Math.random(),
      author: { id: 100 },
      current_user: { can_edit: canEdit },
      isEditing: false,
    });

    beforeEach(() => {
      window.gon.current_user_id = 1;
    });

    it('turns editing on for the last owned and editable note', () => {
      const ownedEditableNote = createOwnedNote(true);
      useDiffDiscussions().discussions = [
        {
          id: 'abc',
          notes: [
            createForeignNote(),
            createOwnedNote(false),
            ownedEditableNote,
            createForeignNote(false),
          ],
        },
      ];
      expect(useDiffDiscussions().requestLastNoteEditing(useDiffDiscussions().discussions[0])).toBe(
        true,
      );
      expect(useDiffDiscussions().discussions[0].notes.map((note) => note.isEditing)).toStrictEqual(
        [false, false, true, false],
      );
    });

    it('returns false when no notes are editable in a discussion', () => {
      useDiffDiscussions().discussions = [
        { id: 'abc', notes: [createOwnedNote(false), createForeignNote(false)] },
      ];
      expect(useDiffDiscussions().requestLastNoteEditing(useDiffDiscussions().discussions[0])).toBe(
        false,
      );
      expect(useDiffDiscussions().discussions[0].notes.every((n) => !n.isEditing)).toBe(true);
    });

    it('returns false when no notes are owned in a discussion', () => {
      useDiffDiscussions().discussions = [{ id: 'abc', notes: [createForeignNote()] }];
      expect(useDiffDiscussions().requestLastNoteEditing(useDiffDiscussions().discussions[0])).toBe(
        false,
      );
      expect(useDiffDiscussions().discussions[0].notes.every((n) => !n.isEditing)).toBe(true);
    });
  });

  describe('addNewLineDiscussionForm', () => {
    const defaultPosition = {
      oldPath: 'old/file.js',
      newPath: 'new/file.js',
      oldLine: 10,
      newLine: 20,
    };
    const formId = 'old/file.js-new/file.js-10-20';

    it('returns id if form already exists', () => {
      useDiffDiscussions().discussions = [{ id: formId }];
      expect(useDiffDiscussions().addNewLineDiscussionForm(defaultPosition)).toBe(formId);
    });

    it('adds a new discussion form if none exists', () => {
      useDiffDiscussions().discussions = [];

      const result = useDiffDiscussions().addNewLineDiscussionForm(defaultPosition);

      const newDiscussion = useDiffDiscussions().discussions[0];
      expect(useDiffDiscussions().discussions).toHaveLength(1);
      expect(newDiscussion.id).toBe(formId);
      expect(newDiscussion.diff_discussion).toBe(true);
      expect(newDiscussion.isForm).toBe(true);
      expect(newDiscussion.noteBody).toBe('');
      expect(newDiscussion.shouldFocus).toBe(true);
      expect(newDiscussion.position).toStrictEqual({
        old_path: defaultPosition.oldPath,
        new_path: defaultPosition.newPath,
        old_line: defaultPosition.oldLine,
        new_line: defaultPosition.newLine,
      });
      expect(result).toBe(undefined);
    });

    it.each`
      oldLine                    | newLine
      ${null}                    | ${defaultPosition.newLine}
      ${defaultPosition.oldLine} | ${null}
    `(
      `starts replying if an existing discussion is found at the $position position`,
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
        useDiffDiscussions().discussions = [existingDiscussion];

        const result = useDiffDiscussions().addNewLineDiscussionForm(testPosition);

        expect(useDiffDiscussions().discussions[0].repliesExpanded).toBe(true);
        expect(useDiffDiscussions().discussions[0].isReplying).toBe(true);
        expect(result).toBe(existingDiscussion.id);
      },
    );

    it('calls setFileDiscussionsHidden to show discussions when adding a new form', () => {
      useDiffDiscussions().discussions = [];
      const spy = jest.spyOn(useDiffDiscussions(), 'setFileDiscussionsHidden');

      useDiffDiscussions().addNewLineDiscussionForm(defaultPosition);

      expect(spy).toHaveBeenCalledWith(defaultPosition.oldPath, defaultPosition.newPath, false);
    });
  });

  describe('removeNewLineDiscussionForm', () => {
    it('removes the discussion form from the list', () => {
      const discussionToHide = { id: 'form-1', isForm: true };
      const otherDiscussion = { id: 'form-2', isForm: true };
      useDiffDiscussions().discussions = [discussionToHide, otherDiscussion];

      useDiffDiscussions().removeNewLineDiscussionForm(discussionToHide);

      expect(useDiffDiscussions().discussions).toHaveLength(1);
      expect(useDiffDiscussions().discussions[0].id).toBe('form-2');
    });
  });

  describe('setNewLineDiscussionFormText', () => {
    it('sets the noteBody for the discussion form', () => {
      const discussion = { id: 'form-1', noteBody: 'old text' };
      useDiffDiscussions().discussions = [discussion];
      const newText = 'new text';

      useDiffDiscussions().setNewLineDiscussionFormText(discussion, newText);

      expect(discussion.noteBody).toBe(newText);
    });
  });

  describe('setNewLineDiscussionFormAutofocus', () => {
    it('sets the shouldFocus property for the discussion form', () => {
      const discussion = { id: 'form-1', shouldFocus: true };
      useDiffDiscussions().discussions = [discussion];

      useDiffDiscussions().setNewLineDiscussionFormAutofocus(discussion, false);

      expect(discussion.shouldFocus).toBe(false);
    });
  });

  describe('getDiscussionById', () => {
    it('returns discussion', () => {
      const targetDiscussion = { id: 'efg' };
      useDiffDiscussions().discussions = [{ id: 'abc' }, targetDiscussion];
      expect(useDiffDiscussions().getDiscussionById(targetDiscussion.id)).toStrictEqual(
        targetDiscussion,
      );
    });
  });

  describe('toggleAward', () => {
    beforeEach(() => {
      window.gon.current_user_id = 1;
      window.gon.current_user_fullname = 'Test User';
      window.gon.current_username = 'testuser';
    });

    it('adds award when it does not exist', () => {
      const note = { id: 'foo', award_emoji: [] };
      useDiffDiscussions().discussions = [{ id: 'abc', notes: [{}, note] }];

      useDiffDiscussions().toggleAward({ note, award: 'thumbsup' });

      expect(useDiffDiscussions().discussions[0].notes[1].award_emoji).toHaveLength(1);
      expect(useDiffDiscussions().discussions[0].notes[1].award_emoji[0]).toStrictEqual({
        name: 'thumbsup',
        user: {
          id: 1,
          name: 'Test User',
          username: 'testuser',
        },
      });
    });

    it('removes award when current user already awarded it', () => {
      const note = {
        id: 'foo',
        award_emoji: [
          {
            name: 'thumbsup',
            user: { id: 1, name: 'Test User', username: 'testuser' },
          },
        ],
      };
      useDiffDiscussions().discussions = [{ id: 'abc', notes: [{}, note] }];

      useDiffDiscussions().toggleAward({ note, award: 'thumbsup' });

      expect(useDiffDiscussions().discussions[0].notes[1].award_emoji).toHaveLength(0);
    });

    it('does not remove award from another user', () => {
      const note = {
        id: 'foo',
        award_emoji: [
          {
            name: 'thumbsup',
            user: { id: 2, name: 'Other User', username: 'otheruser' },
          },
        ],
      };
      useDiffDiscussions().discussions = [{ id: 'abc', notes: [{}, note] }];

      useDiffDiscussions().toggleAward({ note, award: 'thumbsup' });

      expect(useDiffDiscussions().discussions[0].notes[1].award_emoji).toHaveLength(2);
      expect(useDiffDiscussions().discussions[0].notes[1].award_emoji[0].user.id).toBe(2);
      expect(useDiffDiscussions().discussions[0].notes[1].award_emoji[1].user.id).toBe(1);
    });

    it('handles multiple awards from same user', () => {
      const note = {
        id: 'foo',
        award_emoji: [
          {
            name: 'thumbsup',
            user: { id: 1, name: 'Test User', username: 'testuser' },
          },
        ],
      };
      useDiffDiscussions().discussions = [{ id: 'abc', notes: [{}, note] }];

      useDiffDiscussions().toggleAward({ note, award: 'heart' });

      expect(useDiffDiscussions().discussions[0].notes[1].award_emoji).toHaveLength(2);
      expect(useDiffDiscussions().discussions[0].notes[1].award_emoji[1].name).toBe('heart');
    });
  });

  describe('setFileDiscussionsHidden', () => {
    beforeEach(() => {
      useDiffDiscussions().discussions = [
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

      expect(useDiffDiscussions().discussions[0].hidden).toBe(true);
      expect(useDiffDiscussions().discussions[1].hidden).toBe(true);
    });

    it('shows all discussions for a file when newState is false', () => {
      useDiffDiscussions().setFileDiscussionsHidden('file1.js', 'file1.js', true);
      useDiffDiscussions().setFileDiscussionsHidden('file1.js', 'file1.js', false);

      expect(useDiffDiscussions().discussions[0].hidden).toBe(false);
      expect(useDiffDiscussions().discussions[1].hidden).toBe(false);
    });
  });

  describe('allNotesById', () => {
    it('returns all notes by id', () => {
      const note1 = { id: 'foo' };
      const note2 = { id: 'bar' };
      useDiffDiscussions().discussions = [
        { id: 'abc', notes: [note1] },
        { id: 'bcd', notes: [note2] },
      ];
      expect(useDiffDiscussions().allNotesById).toStrictEqual({
        [note1.id]: note1,
        [note2.id]: note2,
      });
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
      useDiffDiscussions().discussions = [
        matchingDiscussion,
        { ...matchingDiscussion, id: 'match2' },
        { ...matchingDiscussion, isForm: true, id: 'notmatch1' },
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
      useDiffDiscussions().discussions = [
        { ...matchingDiscussion, isForm: true, id: 'notmatch1' },
        { ...matchingDiscussion, diff_discussion: false, id: 'notmatch2' },
      ];

      const found = useDiffDiscussions().findDiscussionsForPosition(position);

      expect(found).toHaveLength(0);
    });
  });

  describe('findDiscussionsForFile', () => {
    beforeEach(() => {
      useDiffDiscussions().discussions = [
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
});
