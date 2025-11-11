import { createPinia, setActivePinia } from 'pinia';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';

describe('diffDiscussions store', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  describe('setInitialDiscussions', () => {
    it('sets transformed initial discussions', () => {
      const discussions = [{ id: 'abc', notes: [{ id: 'bcd' }] }];
      useDiffDiscussions().setInitialDiscussions(discussions);
      expect(useDiffDiscussions().discussions[0].repliesExpanded).toBe(true);
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
      expect(useDiffDiscussions().discussions[0].notes[1]).toBe(undefined);
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

  describe('deleteNote', () => {
    it('deletes existing note', () => {
      const notes = { id: 'foo', discussion_id: 'abc', note: 'Hello!' };
      useDiffDiscussions().discussions = [{ id: 'abc', notes: [notes] }];
      useDiffDiscussions().deleteNote(notes);
      expect(useDiffDiscussions().discussions[0].notes).toHaveLength(0);
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
});
