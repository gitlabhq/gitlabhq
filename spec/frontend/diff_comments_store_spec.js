/* global CommentsStore */

import '~/diff_notes/models/discussion';
import '~/diff_notes/models/note';
import '~/diff_notes/stores/comments';

function createDiscussion(noteId = 1, resolved = true) {
  CommentsStore.create({
    discussionId: 'a',
    noteId,
    canResolve: true,
    resolved,
    resolvedBy: 'test',
    authorName: 'test',
    authorAvatar: 'test',
    noteTruncated: 'test...',
  });
}

beforeEach(() => {
  CommentsStore.state = {};
});

describe('New discussion', () => {
  it('creates new discussion', () => {
    expect(Object.keys(CommentsStore.state).length).toBe(0);
    createDiscussion();

    expect(Object.keys(CommentsStore.state).length).toBe(1);
  });

  it('creates new note in discussion', () => {
    createDiscussion();
    createDiscussion(2);

    const discussion = CommentsStore.state.a;

    expect(Object.keys(discussion.notes).length).toBe(2);
  });
});

describe('Get note', () => {
  beforeEach(() => {
    createDiscussion();
  });

  it('gets note by ID', () => {
    const note = CommentsStore.get('a', 1);

    expect(note).toBeDefined();
    expect(note.id).toBe(1);
  });
});

describe('Delete discussion', () => {
  beforeEach(() => {
    createDiscussion();
  });

  it('deletes discussion by ID', () => {
    CommentsStore.delete('a', 1);

    expect(Object.keys(CommentsStore.state).length).toBe(0);
  });

  it('deletes discussion when no more notes', () => {
    createDiscussion();
    createDiscussion(2);

    expect(Object.keys(CommentsStore.state).length).toBe(1);
    expect(Object.keys(CommentsStore.state.a.notes).length).toBe(2);

    CommentsStore.delete('a', 1);
    CommentsStore.delete('a', 2);

    expect(Object.keys(CommentsStore.state).length).toBe(0);
  });
});

describe('Update note', () => {
  beforeEach(() => {
    createDiscussion();
  });

  it('updates note to be unresolved', () => {
    CommentsStore.update('a', 1, false, 'test');

    const note = CommentsStore.get('a', 1);

    expect(note.resolved).toBe(false);
  });
});

describe('Discussion resolved', () => {
  beforeEach(() => {
    createDiscussion();
  });

  it('is resolved with single note', () => {
    const discussion = CommentsStore.state.a;

    expect(discussion.isResolved()).toBe(true);
  });

  it('is unresolved with 2 notes', () => {
    const discussion = CommentsStore.state.a;
    createDiscussion(2, false);

    expect(discussion.isResolved()).toBe(false);
  });

  it('is resolved with 2 notes', () => {
    const discussion = CommentsStore.state.a;
    createDiscussion(2);

    expect(discussion.isResolved()).toBe(true);
  });

  it('resolve all notes', () => {
    const discussion = CommentsStore.state.a;
    createDiscussion(2, false);

    discussion.resolveAllNotes();

    expect(discussion.isResolved()).toBe(true);
  });

  it('unresolve all notes', () => {
    const discussion = CommentsStore.state.a;
    createDiscussion(2);

    discussion.unResolveAllNotes();

    expect(discussion.isResolved()).toBe(false);
  });
});
