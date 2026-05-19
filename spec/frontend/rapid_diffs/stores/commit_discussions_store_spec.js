import MockAdapter from 'axios-mock-adapter';
import { createTestingPinia } from '@pinia/testing';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_OK,
  HTTP_STATUS_GONE,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
} from '~/lib/utils/http_status';
import { useCommitDiffDiscussions } from '~/rapid_diffs/stores/commit_discussions_store';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import { useDiscussions } from '~/notes/store/discussions';

describe('commitDiffDiscussions store', () => {
  let mockAxios;

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
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
    'addNewLineDiscussionForm',
    'replaceDiscussionForm',
    'removeNewLineDiscussionForm',
    'setDiscussionFormText',
    'setNewLineDiscussionFormAutofocus',
    'setFileDiscussionsHidden',
    'setDiscussionsEndpoint',
    'createNewDiscussion',
    'createLineDiscussion',
    'replyToDiscussion',
    'saveNote',
    'destroyNote',
    'toggleAwardOnNote',
    'setPositionDiscussionsHidden',
  ])('exposes %s action', (action) => {
    expect(useCommitDiffDiscussions()[action]).toEqual(expect.any(Function));
  });

  it.each([
    'discussionsWithForms',
    'findAllImageDiscussionsForFile',
    'findDiscussionsForFile',
    'findLinePositionsForFile',
    'findLineDiscussionsForPosition',
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

  describe('API actions', () => {
    const endpoint = '/api/discussions';

    beforeEach(() => {
      useCommitDiffDiscussions().setDiscussionsEndpoint(endpoint);
    });

    describe('createNewDiscussion', () => {
      it('posts note data and adds discussion to store', async () => {
        const discussion = { id: 'new-1', notes: [] };
        mockAxios.onPost(endpoint).reply(HTTP_STATUS_OK, { discussion });

        await useCommitDiffDiscussions().createNewDiscussion({ note: 'test' });

        expect(JSON.parse(mockAxios.history.post[0].data)).toEqual({ note: { note: 'test' } });
        expect(useDiscussions().discussions).toEqual(
          expect.arrayContaining([expect.objectContaining(discussion)]),
        );
      });
    });

    describe('createLineDiscussion', () => {
      it('posts note data and replaces form with discussion', async () => {
        const formDiscussion = { id: 'form-1', isForm: true };
        const discussion = { id: 'new-1', notes: [] };
        mockAxios.onPost(endpoint).reply(HTTP_STATUS_OK, { discussion });
        useDiffDiscussions().discussionForms.push(formDiscussion);

        await useCommitDiffDiscussions().createLineDiscussion(formDiscussion, {
          position: { old_line: 1 },
          note: 'test',
        });

        expect(useDiffDiscussions().discussionForms).not.toContainEqual(formDiscussion);
        expect(useDiscussions().discussions).toEqual(
          expect.arrayContaining([expect.objectContaining(discussion)]),
        );
      });
    });

    describe('replyToDiscussion', () => {
      it('posts reply and replaces discussion', async () => {
        const original = { id: 'disc-1', reply_id: 'reply-1', notes: [{ id: 1 }] };
        const updated = { id: 'disc-1', notes: [{ id: 1 }, { id: 2 }] };
        mockAxios.onPost(endpoint).reply(HTTP_STATUS_OK, { discussion: updated });
        useDiscussions().discussions = [original];

        await useCommitDiffDiscussions().replyToDiscussion(original, 'reply text');

        expect(JSON.parse(mockAxios.history.post[0].data)).toEqual({
          in_reply_to_discussion_id: 'reply-1',
          note: { note: 'reply text' },
        });
        expect(useDiscussions().discussions[0].id).toBe('disc-1');
        expect(useDiscussions().discussions[0].notes).toHaveLength(2);
      });
    });

    describe('saveNote', () => {
      it('puts note data and updates note in store', async () => {
        const note = { id: 1, path: '/note/1', noteable_id: 10 };
        const updatedNote = { id: 1, body: 'updated' };
        mockAxios.onPut('/note/1').reply(HTTP_STATUS_OK, { note: updatedNote });
        useDiscussions().discussions = [{ id: 'disc-1', notes: [note] }];

        await useCommitDiffDiscussions().saveNote(note, 'updated');

        expect(useDiscussions().discussions[0].notes[0]).toEqual(
          expect.objectContaining(updatedNote),
        );
      });

      it('deletes note and resolves when server returns GONE', async () => {
        const note = { id: 1, path: '/note/1', noteable_id: 10, discussion_id: 'disc-1' };
        mockAxios.onPut('/note/1').reply(HTTP_STATUS_GONE);
        useDiscussions().discussions = [{ id: 'disc-1', notes: [note] }];

        await useCommitDiffDiscussions().saveNote(note, 'updated');

        expect(useDiscussions().discussions).toHaveLength(0);
      });

      it('re-throws on other errors', async () => {
        const note = { id: 1, path: '/note/1', noteable_id: 10 };
        mockAxios.onPut('/note/1').reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        await expect(useCommitDiffDiscussions().saveNote(note, 'updated')).rejects.toThrow();
      });
    });

    describe('destroyNote', () => {
      it('sends delete and removes note from store', async () => {
        const note = { id: 1, path: '/note/1', discussion_id: 'disc-1' };
        mockAxios.onDelete('/note/1').reply(HTTP_STATUS_OK);
        useDiscussions().discussions = [{ id: 'disc-1', notes: [note] }];

        await useCommitDiffDiscussions().destroyNote(note);

        expect(mockAxios.history.delete).toHaveLength(1);
      });
    });

    describe('toggleAwardOnNote', () => {
      it('posts award toggle and updates store', async () => {
        const note = {
          id: 1,
          toggle_award_path: '/award/1',
          award_emoji: [],
        };
        mockAxios.onPost('/award/1').reply(HTTP_STATUS_OK);
        useDiscussions().discussions = [{ id: 'disc-1', notes: [note] }];

        await useCommitDiffDiscussions().toggleAwardOnNote(note, 'thumbsup');

        expect(JSON.parse(mockAxios.history.post[0].data)).toEqual({ name: 'thumbsup' });
      });
    });
  });
});
