import { createTestingPinia } from '@pinia/testing';
import { useMergeRequestDiscussions } from '~/merge_request/stores/merge_request_discussions';
import { useMergeRequestVersions } from '~/merge_request/stores/merge_request_versions';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { useDiscussions } from '~/notes/store/discussions';
import { useNotes } from '~/notes/store/legacy_notes';

jest.mock('~/notes/store/legacy_notes');

describe('mergeRequestDiscussions store', () => {
  let store;
  let mockNotesStore;

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    mockNotesStore = {
      fetchNotes: jest.fn().mockResolvedValue(),
      createNewNote: jest.fn().mockResolvedValue({ id: 'new-1' }),
      saveNote: jest.fn().mockResolvedValue(),
      replyToDiscussion: jest.fn().mockResolvedValue({ discussion: { id: 'disc-1' } }),
      updateNote: jest.fn().mockResolvedValue({ id: 1, body: 'updated' }),
      deleteNote: jest.fn().mockResolvedValue(),
      toggleAwardRequest: jest.fn().mockResolvedValue(),
      toggleResolveNote: jest.fn().mockResolvedValue(),
      noteableData: {
        create_note_path: '/api/notes',
        noteableType: 'MergeRequest',
        id: 42,
        diff_head_sha: 'abc123',
        targetType: 'merge_request',
      },
    };
    useNotes.mockReturnValue(mockNotesStore);
    useMergeRequestVersions().setVersions({
      sourceVersions: [{ selected: true, base_sha: 'base000', head_sha: 'head222' }],
      targetVersions: [{ selected: true, start_sha: 'start111' }],
    });
    store = useMergeRequestDiscussions();
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
    'replyToLineDiscussion',
    'addNewLineDiscussionForm',
    'replaceDiscussionForm',
    'removeNewLineDiscussionForm',
    'setDiscussionFormText',
    'setNewLineDiscussionFormAutofocus',
    'setFileDiscussionsHidden',
    'addNewFileDiscussionForm',
    'removeNewFileDiscussionForm',
    'createNewDiscussion',
    'createLineDiscussion',
    'replyToDiscussion',
    'saveNote',
    'destroyNote',
    'toggleAwardOnNote',
    'toggleResolveNote',
    'setPositionDiscussionsHidden',
  ])('exposes %s action', (action) => {
    expect(store[action]).toEqual(expect.any(Function));
  });

  it.each([
    'discussionForms',
    'discussionsWithForms',
    'getImageDiscussions',
    'findDiscussionsForPosition',
    'findDiscussionsForFile',
    'findAllDiscussionsForFile',
    'findVisibleDiscussionsForFile',
    'findFileDiscussionsForFile',
  ])('exposes %s getter', (getter) => {
    expect(store[getter]).toBeDefined();
  });

  describe('fetchNotes', () => {
    it('delegates to the legacy notes store', async () => {
      await store.fetchNotes();
      expect(mockNotesStore.fetchNotes).toHaveBeenCalled();
    });

    it('marks resolved discussions as hidden after fetching', async () => {
      const resolvedDiscussion = { id: '1', resolvable: true, resolved: true };
      const unresolvedDiscussion = { id: '2', resolvable: true, resolved: false };
      const nonResolvableDiscussion = { id: '3', resolvable: false };
      useDiscussions().discussions = [
        resolvedDiscussion,
        unresolvedDiscussion,
        nonResolvableDiscussion,
      ];

      await store.fetchNotes();

      expect(resolvedDiscussion).toMatchObject({ hidden: true });
      expect(unresolvedDiscussion).not.toHaveProperty('hidden');
      expect(nonResolvableDiscussion).not.toHaveProperty('hidden');
    });
  });

  describe('createNewDiscussion', () => {
    it('delegates to notes store createNewNote', async () => {
      await store.createNewDiscussion({ note: 'test' });
      expect(mockNotesStore.createNewNote).toHaveBeenCalledWith({
        endpoint: '/api/notes',
        data: { note: { note: 'test' } },
      });
    });
  });

  describe('createLineDiscussion', () => {
    it('delegates to notes store saveNote and removes the form', async () => {
      const formDiscussion = { id: 'form-1', isForm: true };
      useDiffDiscussions().discussionForms.push(formDiscussion);

      await store.createLineDiscussion(formDiscussion, {
        position: { old_line: 1 },
        lineChange: { change: 'added', position: 'new' },
        lineCode: 'hash_0_1',
        note: 'test',
      });

      expect(mockNotesStore.saveNote).toHaveBeenCalledWith({
        endpoint: '/api/notes',
        data: {
          view: useDiffsView().viewType,
          line_type: 'new',
          merge_request_diff_head_sha: 'head222',
          note_project_id: '',
          target_type: 'merge_request',
          target_id: 42,
          return_discussion: true,
          note: {
            note: 'test',
            position: JSON.stringify({
              base_sha: 'base000',
              start_sha: 'start111',
              head_sha: 'head222',
              old_line: 1,
              position_type: 'text',
              line_range: null,
              ignore_whitespace_change: !useDiffsView().showWhitespace,
            }),
            noteable_type: 'MergeRequest',
            noteable_id: 42,
            commit_id: null,
            type: 'DiffNote',
            line_code: 'hash_0_1',
          },
        },
      });
      expect(useDiffDiscussions().discussionForms).not.toContainEqual(formDiscussion);
    });
  });

  describe('replyToDiscussion', () => {
    it('delegates to notes store saveNote with reply data', async () => {
      const discussion = { id: 'disc-1', reply_id: 'reply-1' };

      await store.replyToDiscussion(discussion, 'reply text');

      expect(mockNotesStore.saveNote).toHaveBeenCalledWith({
        endpoint: '/api/notes',
        data: {
          in_reply_to_discussion_id: 'reply-1',
          target_type: 'merge_request',
          note: { note: 'reply text' },
          merge_request_diff_head_sha: 'head222',
        },
      });
    });
  });

  describe('saveNote', () => {
    it('delegates to notes store updateNote', async () => {
      const note = { id: 1, path: '/note/1', noteable_id: 10 };

      await store.saveNote(note, 'updated');

      expect(mockNotesStore.updateNote).toHaveBeenCalledWith({
        endpoint: '/note/1',
        note: {
          target_type: 'merge_request',
          target_id: 10,
          note: { note: 'updated' },
        },
      });
    });
  });

  describe('destroyNote', () => {
    it('delegates to notes store deleteNote', async () => {
      const note = { id: 1, path: '/note/1' };

      await store.destroyNote(note);

      expect(mockNotesStore.deleteNote).toHaveBeenCalledWith(note);
    });
  });

  describe('toggleAwardOnNote', () => {
    it('delegates to notes store toggleAwardRequest', async () => {
      const note = { id: 1, toggle_award_path: '/award/1' };

      await store.toggleAwardOnNote(note, 'thumbsup');

      expect(mockNotesStore.toggleAwardRequest).toHaveBeenCalledWith({
        endpoint: '/award/1',
        awardName: 'thumbsup',
        noteId: 1,
      });
    });
  });

  describe('replyToLineDiscussion', () => {
    it('always creates a new discussion form', () => {
      const lineRange = {
        start: { old_line: 5, new_line: 15 },
        end: { old_line: 10, new_line: 20 },
      };

      store.replyToLineDiscussion({ oldPath: 'old/file.js', newPath: 'new/file.js', lineRange });

      const forms = useDiffDiscussions().discussionForms;
      expect(forms).toHaveLength(1);
      expect(forms[0].position.line_range).toStrictEqual(lineRange);
    });
  });

  describe('toggleResolveNote', () => {
    it('delegates to the legacy notes store', async () => {
      const discussion = {
        id: 'discussion-1',
        resolved: false,
        resolve_path: '/resolve/path',
      };

      await store.toggleResolveNote(discussion);

      expect(mockNotesStore.toggleResolveNote).toHaveBeenCalledWith({
        endpoint: '/resolve/path',
        isResolved: false,
        discussion: true,
        discussionId: 'discussion-1',
      });
    });
  });
});
