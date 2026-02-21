import { createTestingPinia } from '@pinia/testing';
import { useDiscussions } from '~/notes/store/discussions';

describe('discussions store', () => {
  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    window.gon.current_user_id = 1;
  });

  describe('setInitialDiscussions', () => {
    it('sets transformed initial discussions', () => {
      const discussions = [{ id: 'abc', notes: [{ id: 'bcd' }] }];
      useDiscussions().setInitialDiscussions(discussions);
      expect(useDiscussions().discussions[0].repliesExpanded).toBe(true);
      expect(useDiscussions().discussions[0].isReplying).toBe(false);
      expect(useDiscussions().discussions[0].hidden).toBe(false);
      expect(useDiscussions().discussions[0].notes[0].isEditing).toBe(false);
      expect(useDiscussions().discussions[0].notes[0].editedNote).toBeNull();
    });

    it('does not overwrite existing properties', () => {
      const discussions = [{ id: 'abc', notes: [{ id: 'bcd' }], hidden: true }];
      useDiscussions().setInitialDiscussions(discussions);
      expect(useDiscussions().discussions[0].hidden).toBe(true);
    });
  });

  describe('replaceDiscussion', () => {
    it('replaces an old discussion with a new, transformed discussion', () => {
      const oldDiscussion = { id: 'old' };
      const newDiscussion = { id: 'new', notes: [{ id: 'note2' }] };
      useDiscussions().discussions = [oldDiscussion, { id: 'other' }];

      useDiscussions().replaceDiscussion(oldDiscussion, newDiscussion);

      const store = useDiscussions();
      expect(store.discussions).toHaveLength(2);
      expect(store.discussions[0].id).toBe('new');
      expect(store.discussions[0].repliesExpanded).toBe(true);
      expect(store.discussions[0].notes[0].isEditing).toBe(false);
      expect(store.discussions[1].id).toBe('other');
    });
  });

  describe('addDiscussion', () => {
    it('adds a transformed discussion', () => {
      useDiscussions().discussions = [];
      useDiscussions().addDiscussion({ id: 'new', notes: [{ id: 'n1' }] });
      expect(useDiscussions().discussions).toHaveLength(1);
      expect(useDiscussions().discussions[0].id).toBe('new');
      expect(useDiscussions().discussions[0].repliesExpanded).toBe(true);
    });
  });

  describe('deleteDiscussion', () => {
    it('deletes existing discussion', () => {
      const discussion = { id: 'foo', notes: [{ id: 'n1' }] };
      useDiscussions().discussions = [discussion];
      useDiscussions().deleteDiscussion(discussion);
      expect(useDiscussions().discussions).toHaveLength(0);
    });
  });

  describe('toggleDiscussionReplies', () => {
    it('toggles repliesExpanded', () => {
      useDiscussions().discussions = [{ id: 'abc', repliesExpanded: true }];
      useDiscussions().toggleDiscussionReplies(useDiscussions().discussions[0]);
      expect(useDiscussions().discussions[0].repliesExpanded).toBe(false);
    });
  });

  describe('expandDiscussionReplies', () => {
    it('expands', () => {
      useDiscussions().discussions = [{ id: 'abc', repliesExpanded: false }];
      useDiscussions().expandDiscussionReplies(useDiscussions().discussions[0]);
      expect(useDiscussions().discussions[0].repliesExpanded).toBe(true);
    });
  });

  describe('startReplying', () => {
    it('expands and sets isReplying to true', () => {
      useDiscussions().discussions = [{ id: 'abc', repliesExpanded: false, isReplying: false }];
      useDiscussions().startReplying(useDiscussions().discussions[0]);
      expect(useDiscussions().discussions[0].repliesExpanded).toBe(true);
      expect(useDiscussions().discussions[0].isReplying).toBe(true);
    });
  });

  describe('stopReplying', () => {
    it('sets isReplying to false', () => {
      useDiscussions().discussions = [{ id: 'abc', isReplying: true }];
      useDiscussions().stopReplying(useDiscussions().discussions[0]);
      expect(useDiscussions().discussions[0].isReplying).toBe(false);
    });
  });

  describe('addNote', () => {
    it('adds a note', () => {
      const note = { id: 'bar', discussion_id: 'abc' };
      useDiscussions().discussions = [{ id: 'abc', notes: [{ id: 'foo', discussion_id: 'abc' }] }];
      useDiscussions().addNote(note);
      expect(useDiscussions().discussions[0].notes[1]).toStrictEqual(note);
    });

    it('does not add a note when it exists', () => {
      const note = { id: 'foo', discussion_id: 'abc' };
      useDiscussions().discussions = [{ id: 'abc', notes: [{ id: 'foo', discussion_id: 'abc' }] }];
      useDiscussions().addNote(note);
      expect(useDiscussions().discussions[0].notes).toHaveLength(1);
    });
  });

  describe('updateNote', () => {
    it('updates existing note', () => {
      useDiscussions().discussions = [
        { id: 'abc', notes: [{ id: 'foo', discussion_id: 'abc', note: 'Hello!' }] },
      ];
      useDiscussions().updateNote({ id: 'foo', discussion_id: 'abc', note: 'Hello world!' });
      expect(useDiscussions().discussions[0].notes[0].note).toBe('Hello world!');
    });
  });

  describe('updateNoteTextById', () => {
    it('updates note text by id', () => {
      useDiscussions().discussions = [
        { id: 'abc', notes: [{ id: 'foo', discussion_id: 'abc', note: 'Hello!' }] },
      ];
      useDiscussions().updateNoteTextById('foo', 'Updated text');
      expect(useDiscussions().discussions[0].notes[0].note).toBe('Updated text');
    });
  });

  describe('editNote', () => {
    it('sets editedNote on the note', () => {
      const value = 'edit';
      const note = { id: 'foo', discussion_id: 'abc', note: 'Hello!' };
      useDiscussions().discussions = [{ id: 'abc', notes: [note] }];
      useDiscussions().editNote({ note, value });
      expect(useDiscussions().discussions[0].notes[0].note).toBe('Hello!');
      expect(useDiscussions().discussions[0].notes[0].editedNote).toBe(value);
    });
  });

  describe('deleteNote', () => {
    it('deletes existing note', () => {
      const note = { id: 'foo', discussion_id: 'abc', note: 'Hello!' };
      const remainingNote = {};
      useDiscussions().discussions = [{ id: 'abc', notes: [note, remainingNote] }];
      useDiscussions().deleteNote(note);
      expect(useDiscussions().discussions[0].notes).toHaveLength(1);
      expect(useDiscussions().discussions[0].notes[0]).toStrictEqual(remainingNote);
    });

    it('deletes discussion when no notes left', () => {
      const note = { id: 'foo', discussion_id: 'abc', note: 'Hello!' };
      useDiscussions().discussions = [{ id: 'abc', notes: [note] }];
      useDiscussions().deleteNote(note);
      expect(useDiscussions().discussions).toHaveLength(0);
    });
  });

  describe('setEditingMode', () => {
    it('sets editing mode to true', () => {
      const note = { id: 'foo', isEditing: false };
      useDiscussions().discussions = [{ id: 'efg', notes: [note] }];
      useDiscussions().setEditingMode(useDiscussions().discussions[0].notes[0], true);
      expect(useDiscussions().discussions[0].notes[0].isEditing).toBe(true);
    });

    it('clears editedNote when setting editing mode to false', () => {
      const note = { id: 'foo', isEditing: true, editedNote: 'some text' };
      useDiscussions().discussions = [{ id: 'efg', notes: [note] }];
      useDiscussions().setEditingMode(useDiscussions().discussions[0].notes[0], false);
      expect(useDiscussions().discussions[0].notes[0].isEditing).toBe(false);
      expect(useDiscussions().discussions[0].notes[0].editedNote).toBeUndefined();
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

    it('turns editing on for the last owned and editable note', () => {
      const ownedEditableNote = createOwnedNote(true);
      useDiscussions().discussions = [
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
      expect(useDiscussions().requestLastNoteEditing(useDiscussions().discussions[0])).toBe(true);
      expect(useDiscussions().discussions[0].notes.map((note) => note.isEditing)).toStrictEqual([
        false,
        false,
        true,
        false,
      ]);
    });

    it('returns false when no notes are editable', () => {
      useDiscussions().discussions = [
        { id: 'abc', notes: [createOwnedNote(false), createForeignNote(false)] },
      ];
      expect(useDiscussions().requestLastNoteEditing(useDiscussions().discussions[0])).toBe(false);
    });

    it('returns false when no notes are owned', () => {
      useDiscussions().discussions = [{ id: 'abc', notes: [createForeignNote()] }];
      expect(useDiscussions().requestLastNoteEditing(useDiscussions().discussions[0])).toBe(false);
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
      useDiscussions().discussions = [{ id: 'abc', notes: [note] }];

      useDiscussions().toggleAward({ note, award: 'thumbsup' });

      expect(note.award_emoji).toHaveLength(1);
      expect(note.award_emoji[0]).toStrictEqual({
        name: 'thumbsup',
        user: { id: 1, name: 'Test User', username: 'testuser' },
      });
    });

    it('removes award when current user already awarded it', () => {
      const note = {
        id: 'foo',
        award_emoji: [{ name: 'thumbsup', user: { id: 1, name: 'Test User' } }],
      };
      useDiscussions().discussions = [{ id: 'abc', notes: [note] }];

      useDiscussions().toggleAward({ note, award: 'thumbsup' });

      expect(note.award_emoji).toHaveLength(0);
    });

    it('does not remove award from another user', () => {
      const note = {
        id: 'foo',
        award_emoji: [{ name: 'thumbsup', user: { id: 2, name: 'Other User' } }],
      };
      useDiscussions().discussions = [{ id: 'abc', notes: [note] }];

      useDiscussions().toggleAward({ note, award: 'thumbsup' });

      expect(note.award_emoji).toHaveLength(2);
    });
  });

  describe('getDiscussionById', () => {
    it('returns discussion', () => {
      const targetDiscussion = { id: 'efg' };
      useDiscussions().discussions = [{ id: 'abc' }, targetDiscussion];
      expect(useDiscussions().getDiscussionById(targetDiscussion.id)).toStrictEqual(
        targetDiscussion,
      );
    });
  });

  describe('allNotesById', () => {
    it('returns all notes by id', () => {
      const note1 = { id: 'foo' };
      const note2 = { id: 'bar' };
      useDiscussions().discussions = [
        { id: 'abc', notes: [note1] },
        { id: 'bcd', notes: [note2] },
      ];
      expect(useDiscussions().allNotesById).toStrictEqual({
        [note1.id]: note1,
        [note2.id]: note2,
      });
    });
  });
});
