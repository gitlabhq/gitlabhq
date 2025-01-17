import MockAdapter from 'axios-mock-adapter';
import { createTestingPinia } from '@pinia/testing';
import { TEST_HOST } from 'helpers/test_constants';
import { sprintf } from '~/locale';
import { createAlert } from '~/alert';
import service from '~/batch_comments/services/drafts_service';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { UPDATE_COMMENT_FORM } from '~/notes/i18n';
import { createTestPiniaAction, createCustomGetters } from 'helpers/pinia_helpers';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useBatchComments } from '~/batch_comments/store';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import * as types from '~/batch_comments/stores/modules/batch_comments/mutation_types';

jest.mock('~/alert');

describe('Batch comments store actions', () => {
  let res = {};
  let mock;
  let legacyNotesGetters = {};
  let batchCommentsGetters = {};
  let store;
  let testAction;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    createTestingPinia({
      stubActions: false,
      plugins: [
        createCustomGetters(() => ({
          legacyDiffs: {},
          legacyNotes: legacyNotesGetters,
          batchComments: batchCommentsGetters,
        })),
        globalAccessorPlugin,
      ],
    });
    useLegacyDiffs();
    useNotes();
    store = useBatchComments();
    testAction = createTestPiniaAction(store);
  });

  afterEach(() => {
    res = {};
    mock.restore();
  });

  describe('saveDraft', () => {
    it('dispatches saveNote on root', () => {
      useNotes().saveNote.mockResolvedValueOnce();
      store.saveDraft({ id: 1 });

      expect(useNotes().saveNote).toHaveBeenCalledWith({ id: 1, isDraft: true });
    });
  });

  describe('addDraftToDiscussion', () => {
    it('commits ADD_NEW_DRAFT if no errors returned', () => {
      res = { id: 1 };
      mock.onAny().reply(HTTP_STATUS_OK, res);

      return testAction(
        store.addDraftToDiscussion,
        { endpoint: TEST_HOST, data: 'test' },
        null,
        [{ type: store[types.ADD_NEW_DRAFT], payload: res }],
        [],
      );
    });

    it('does not commit ADD_NEW_DRAFT if errors returned', () => {
      mock.onAny().reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      return store.addDraftToDiscussion({ endpoint: TEST_HOST, data: 'test' }).catch(() => {
        expect(store[types.ADD_NEW_DRAFT]).not.toHaveBeenCalled();
      });
    });
  });

  describe('createNewDraft', () => {
    it('commits ADD_NEW_DRAFT if no errors returned', () => {
      res = { id: 1 };
      mock.onAny().reply(HTTP_STATUS_OK, res);

      return testAction(
        store.createNewDraft,
        { endpoint: TEST_HOST, data: 'test' },
        null,
        [{ type: store[types.ADD_NEW_DRAFT], payload: res }],
        [],
      );
    });

    it('dispatchs addDraftToFile if draft is on file', () => {
      useLegacyDiffs().addDraftToFile.mockResolvedValueOnce();
      res = { id: 1, position: { position_type: 'file' }, file_path: 'index.js' };
      mock.onAny().reply(HTTP_STATUS_OK, res);

      return testAction(
        store.createNewDraft,
        { endpoint: TEST_HOST, data: 'test' },
        null,
        [{ type: store[types.ADD_NEW_DRAFT], payload: res }],
        [{ type: useLegacyDiffs().addDraftToFile, payload: { draft: res, filePath: 'index.js' } }],
      );
    });

    it('does not commit ADD_NEW_DRAFT if errors returned', () => {
      mock.onAny().reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      return store.createNewDraft({ endpoint: TEST_HOST, data: 'test' }).catch(() => {
        expect(store[types.ADD_NEW_DRAFT]).not.toHaveBeenCalled();
      });
    });
  });

  describe('deleteDraft', () => {
    beforeEach(() => {
      batchCommentsGetters = {
        getNotesData: {
          draftsDiscardPath: TEST_HOST,
        },
      };
    });

    it('commits DELETE_DRAFT if no errors returned', () => {
      res = { id: 1 };
      mock.onAny().reply(HTTP_STATUS_OK);

      return store.deleteDraft({ id: 1 }).then(() => {
        expect(store[types.DELETE_DRAFT]).toHaveBeenCalledWith(1);
      });
    });

    it('does not commit DELETE_DRAFT if errors returned', () => {
      mock.onAny().reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      return store.deleteDraft({ id: 1 }).then(() => {
        expect(store[types.DELETE_DRAFT]).not.toHaveBeenCalled();
      });
    });
  });

  describe('fetchDrafts', () => {
    beforeEach(() => {
      batchCommentsGetters = {
        getNotesData: {
          draftsPath: TEST_HOST,
        },
      };
    });

    it('commits SET_BATCH_COMMENTS_DRAFTS with returned data', () => {
      useNotes().convertToDiscussion.mockResolvedValueOnce();
      store.$patch({ drafts: [{ line_code: '123' }, { line_code: null, discussion_id: '1' }] });
      res = [{ id: 1, discussion_id: '2' }];
      mock.onAny().reply(HTTP_STATUS_OK, res);

      return store.fetchDrafts().then(() => {
        expect(store[types.SET_BATCH_COMMENTS_DRAFTS]).toHaveBeenCalledWith(res);
        expect(useNotes().convertToDiscussion).toHaveBeenCalledWith('2');
      });
    });
  });

  describe('publishReview', () => {
    beforeEach(() => {
      batchCommentsGetters = {
        getNotesData: { draftsPublishPath: TEST_HOST, discussionsPath: TEST_HOST },
      };
    });

    it('dispatches actions & commits', () => {
      mock.onAny().reply(HTTP_STATUS_OK);

      return store.publishReview().then(() => {
        expect(store[types.REQUEST_PUBLISH_REVIEW]).toHaveBeenCalled();
        expect(store[types.RECEIVE_PUBLISH_REVIEW_SUCCESS]).toHaveBeenCalled();
      });
    });

    it('calls service with notes data', () => {
      mock.onAny().reply(HTTP_STATUS_OK);
      jest.spyOn(axios, 'post');

      return store.publishReview({ note: 'test' }).then(() => {
        expect(axios.post.mock.calls[0]).toEqual(['http://test.host', { note: 'test' }]);
      });
    });

    it('dispatches error commits', () => {
      mock.onAny().reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      return store.publishReview().catch(() => {
        expect(store[types.REQUEST_PUBLISH_REVIEW]).toHaveBeenCalled();
        expect(store[types.RECEIVE_PUBLISH_REVIEW_ERROR]).toHaveBeenCalled();
      });
    });
  });

  describe('updateDraft', () => {
    service.update = jest.fn();
    service.update.mockResolvedValue({ data: { id: 1 } });

    let params;

    beforeEach(() => {
      batchCommentsGetters = {
        getNotesData: {
          draftsPath: TEST_HOST,
        },
      };

      res = { id: 1 };
      mock.onAny().reply(HTTP_STATUS_OK, res);
      params = { note: { id: 1 }, noteText: 'test' };
    });

    it('commits RECEIVE_DRAFT_UPDATE_SUCCESS with returned data', () => {
      return store.updateDraft({ ...params, callback() {} }).then(() => {
        expect(store[types.RECEIVE_DRAFT_UPDATE_SUCCESS]).toHaveBeenCalledWith({ id: 1 });
      });
    });

    it('calls passed callback', () => {
      const callback = jest.fn();
      return store.updateDraft({ ...params, callback }).then(() => {
        expect(callback).toHaveBeenCalled();
      });
    });

    it('does not stringify empty position', () => {
      return store.updateDraft({ ...params, position: {}, callback() {} }).then(() => {
        expect(service.update.mock.calls[0][1].position).toBeUndefined();
      });
    });

    it('stringifies a non-empty position', () => {
      const position = { test: true };
      const expectation = JSON.stringify(position);
      return store.updateDraft({ ...params, position, callback() {} }).then(() => {
        expect(service.update.mock.calls[0][1].position).toBe(expectation);
      });
    });

    describe('when updating a draft returns an error', () => {
      const errorCallback = jest.fn();
      const flashContainer = null;
      const error = 'server error';

      beforeEach(async () => {
        service.update.mockRejectedValue({ response: { data: { errors: error } } });
        await store.updateDraft({ ...params, flashContainer, errorCallback });
      });

      it('renders an error message', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: sprintf(UPDATE_COMMENT_FORM.error, { reason: error }),
          parent: flashContainer,
        });
      });

      it('calls errorCallback', () => {
        expect(errorCallback).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('expandAllDiscussions', () => {
    it('dispatches expandDiscussion for all drafts', () => {
      useNotes().expandDiscussion.mockResolvedValue();
      const state = {
        drafts: [
          {
            discussion_id: '1',
          },
        ],
      };

      return testAction(
        store.expandAllDiscussions,
        null,
        state,
        [],
        [
          {
            type: useNotes().expandDiscussion,
            payload: { discussionId: '1' },
          },
        ],
      );
    });
  });

  describe('scrollToDraft', () => {
    beforeEach(() => {
      window.mrTabs = {
        currentAction: 'notes',
        tabShown: jest.fn(),
      };
    });

    it('scrolls to draft item', () => {
      useLegacyDiffs().setFileCollapsedAutomatically.mockResolvedValueOnce();
      useNotes().expandDiscussion.mockResolvedValueOnce();
      legacyNotesGetters = {
        getDiscussion: () => ({
          id: '1',
          diff_discussion: true,
        }),
      };
      const draft = {
        discussion_id: '1',
        id: '2',
        file_path: 'lib/example.js',
      };

      store.scrollToDraft(draft);

      expect(useLegacyDiffs().setFileCollapsedAutomatically).toHaveBeenCalledWith({
        filePath: draft.file_path,
        collapsed: false,
      });
      expect(useNotes().expandDiscussion).toHaveBeenCalledWith({ discussionId: '1' });
      expect(window.mrTabs.tabShown).toHaveBeenCalledWith('diffs');
    });
  });

  describe('clearDrafts', () => {
    it('commits CLEAR_DRAFTS', () => {
      return testAction(store.clearDrafts, null, null, [{ type: store[types.CLEAR_DRAFTS] }], []);
    });
  });

  describe('discardDrafts', () => {
    beforeEach(() => {
      batchCommentsGetters = {
        getNotesData: { draftsDiscardPath: TEST_HOST },
      };
    });

    it('dispatches actions & commits', async () => {
      mock.onAny().reply(HTTP_STATUS_OK);

      await store.discardDrafts();

      expect(store[types.CLEAR_DRAFTS]).toHaveBeenCalled();
    });

    it('calls createAlert when server returns an error', async () => {
      mock.onAny().reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await store.discardDrafts();

      expect(createAlert).toHaveBeenCalledWith({
        error: expect.anything(),
        captureError: true,
        message: 'An error occurred while discarding your review. Please try again.',
      });
    });
  });
});
