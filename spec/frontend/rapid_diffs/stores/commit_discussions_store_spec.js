import { createTestingPinia } from '@pinia/testing';
import { useCommitDiffDiscussions } from '~/rapid_diffs/stores/commit_discussions_store';
import { useDiscussions } from '~/notes/store/discussions';

describe('commitDiffDiscussions store', () => {
  beforeEach(() => {
    createTestingPinia({ stubActions: false });
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
    expect(useCommitDiffDiscussions()[action]).toEqual(expect.any(Function));
  });

  it.each([
    'discussionsWithForms',
    'getImageDiscussions',
    'findDiscussionsForPosition',
    'findDiscussionsForFile',
    'findAllDiscussionsForFile',
    'findVisibleDiscussionsForFile',
  ])('exposes %s getter', (getter) => {
    expect(useCommitDiffDiscussions()[getter]).toBeDefined();
  });

  describe('timelineDiscussions', () => {
    it('returns non-form, non-diff discussions', () => {
      useDiscussions().discussions = [
        { id: '1', diff_discussion: false, isForm: false },
        { id: '2', diff_discussion: true, isForm: false },
      ];

      expect(useCommitDiffDiscussions().timelineDiscussions).toHaveLength(1);
      expect(useCommitDiffDiscussions().timelineDiscussions[0].id).toBe('1');
    });

    it('returns empty array when no matching discussions', () => {
      useDiscussions().discussions = [{ id: '1', diff_discussion: true }];

      expect(useCommitDiffDiscussions().timelineDiscussions).toHaveLength(0);
    });
  });
});
