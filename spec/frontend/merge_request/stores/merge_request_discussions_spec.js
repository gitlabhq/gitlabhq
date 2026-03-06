import { createTestingPinia } from '@pinia/testing';
import { useMergeRequestDiscussions } from '~/merge_request/stores/merge_request_discussions';
import { useNotes } from '~/notes/store/legacy_notes';

jest.mock('~/notes/store/legacy_notes');

describe('mergeRequestDiscussions store', () => {
  let store;

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    useNotes.mockReturnValue({ fetchNotes: jest.fn().mockResolvedValue() });
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
    'replyToLineDiscussion',
    'addNewLineDiscussionForm',
    'replaceDiscussionForm',
    'removeNewLineDiscussionForm',
    'setNewLineDiscussionFormText',
    'setNewLineDiscussionFormAutofocus',
    'setFileDiscussionsHidden',
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
  ])('exposes %s getter', (getter) => {
    expect(store[getter]).toBeDefined();
  });

  describe('fetchNotes', () => {
    it('delegates to the legacy notes store', async () => {
      await store.fetchNotes();
      expect(useNotes().fetchNotes).toHaveBeenCalled();
    });
  });
});
