import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'jest/helpers/test_constants';
import * as actions from '~/batch_comments/stores/modules/batch_comments/actions';
import axios from '~/lib/utils/axios_utils';

describe('Batch comments store actions', () => {
  let res = {};
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    res = {};
    mock.restore();
  });

  describe('saveDraft', () => {
    it('dispatches saveNote on root', () => {
      const dispatch = jest.fn();

      actions.saveDraft({ dispatch }, { id: 1 });

      expect(dispatch).toHaveBeenCalledWith('saveNote', { id: 1, isDraft: true }, { root: true });
    });
  });

  describe('addDraftToDiscussion', () => {
    it('commits ADD_NEW_DRAFT if no errors returned', done => {
      res = { id: 1 };
      mock.onAny().reply(200, res);

      testAction(
        actions.addDraftToDiscussion,
        { endpoint: TEST_HOST, data: 'test' },
        null,
        [{ type: 'ADD_NEW_DRAFT', payload: res }],
        [],
        done,
      );
    });

    it('does not commit ADD_NEW_DRAFT if errors returned', done => {
      mock.onAny().reply(500);

      testAction(
        actions.addDraftToDiscussion,
        { endpoint: TEST_HOST, data: 'test' },
        null,
        [],
        [],
        done,
      );
    });
  });

  describe('createNewDraft', () => {
    it('commits ADD_NEW_DRAFT if no errors returned', done => {
      res = { id: 1 };
      mock.onAny().reply(200, res);

      testAction(
        actions.createNewDraft,
        { endpoint: TEST_HOST, data: 'test' },
        null,
        [{ type: 'ADD_NEW_DRAFT', payload: res }],
        [],
        done,
      );
    });

    it('does not commit ADD_NEW_DRAFT if errors returned', done => {
      mock.onAny().reply(500);

      testAction(actions.createNewDraft, { endpoint: TEST_HOST, data: 'test' }, null, [], [], done);
    });
  });

  describe('deleteDraft', () => {
    let getters;

    beforeEach(() => {
      getters = {
        getNotesData: {
          draftsDiscardPath: TEST_HOST,
        },
      };
    });

    it('commits DELETE_DRAFT if no errors returned', done => {
      const commit = jest.fn();
      const context = {
        getters,
        commit,
      };
      res = { id: 1 };
      mock.onAny().reply(200);

      actions
        .deleteDraft(context, { id: 1 })
        .then(() => {
          expect(commit).toHaveBeenCalledWith('DELETE_DRAFT', 1);
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not commit DELETE_DRAFT if errors returned', done => {
      const commit = jest.fn();
      const context = {
        getters,
        commit,
      };
      mock.onAny().reply(500);

      actions
        .deleteDraft(context, { id: 1 })
        .then(() => {
          expect(commit).not.toHaveBeenCalledWith('DELETE_DRAFT', 1);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('fetchDrafts', () => {
    let getters;

    beforeEach(() => {
      getters = {
        getNotesData: {
          draftsPath: TEST_HOST,
        },
      };
    });

    it('commits SET_BATCH_COMMENTS_DRAFTS with returned data', done => {
      const commit = jest.fn();
      const context = {
        getters,
        commit,
      };
      res = { id: 1 };
      mock.onAny().reply(200, res);

      actions
        .fetchDrafts(context)
        .then(() => {
          expect(commit).toHaveBeenCalledWith('SET_BATCH_COMMENTS_DRAFTS', { id: 1 });
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('publishReview', () => {
    let dispatch;
    let commit;
    let getters;
    let rootGetters;

    beforeEach(() => {
      dispatch = jest.fn();
      commit = jest.fn();
      getters = {
        getNotesData: { draftsPublishPath: TEST_HOST, discussionsPath: TEST_HOST },
      };
      rootGetters = { discussionsStructuredByLineCode: 'discussions' };
    });

    it('dispatches actions & commits', done => {
      mock.onAny().reply(200);

      actions
        .publishReview({ dispatch, commit, getters, rootGetters })
        .then(() => {
          expect(commit.mock.calls[0]).toEqual(['REQUEST_PUBLISH_REVIEW']);
          expect(commit.mock.calls[1]).toEqual(['RECEIVE_PUBLISH_REVIEW_SUCCESS']);

          expect(dispatch.mock.calls[0]).toEqual(['updateDiscussionsAfterPublish']);
        })
        .then(done)
        .catch(done.fail);
    });

    it('dispatches error commits', done => {
      mock.onAny().reply(500);

      actions
        .publishReview({ dispatch, commit, getters, rootGetters })
        .then(() => {
          expect(commit.mock.calls[0]).toEqual(['REQUEST_PUBLISH_REVIEW']);
          expect(commit.mock.calls[1]).toEqual(['RECEIVE_PUBLISH_REVIEW_ERROR']);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('updateDraft', () => {
    let getters;

    beforeEach(() => {
      getters = {
        getNotesData: {
          draftsPath: TEST_HOST,
        },
      };
    });

    it('commits RECEIVE_DRAFT_UPDATE_SUCCESS with returned data', done => {
      const commit = jest.fn();
      const context = {
        getters,
        commit,
      };
      res = { id: 1 };
      mock.onAny().reply(200, res);

      actions
        .updateDraft(context, { note: { id: 1 }, noteText: 'test', callback() {} })
        .then(() => {
          expect(commit).toHaveBeenCalledWith('RECEIVE_DRAFT_UPDATE_SUCCESS', { id: 1 });
        })
        .then(done)
        .catch(done.fail);
    });

    it('calls passed callback', done => {
      const commit = jest.fn();
      const context = {
        getters,
        commit,
      };
      const callback = jest.fn();
      res = { id: 1 };
      mock.onAny().reply(200, res);

      actions
        .updateDraft(context, { note: { id: 1 }, noteText: 'test', callback })
        .then(() => {
          expect(callback).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('expandAllDiscussions', () => {
    it('dispatches expandDiscussion for all drafts', done => {
      const state = {
        drafts: [
          {
            discussion_id: '1',
          },
        ],
      };

      testAction(
        actions.expandAllDiscussions,
        null,
        state,
        [],
        [
          {
            type: 'expandDiscussion',
            payload: { discussionId: '1' },
          },
        ],
        done,
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
      const dispatch = jest.fn();
      const rootGetters = {
        getDiscussion: () => ({
          id: '1',
          diff_discussion: true,
        }),
      };
      const draft = {
        discussion_id: '1',
        id: '2',
      };

      actions.scrollToDraft({ dispatch, rootGetters }, draft);

      expect(dispatch.mock.calls[0]).toEqual([
        'expandDiscussion',
        { discussionId: '1' },
        { root: true },
      ]);

      expect(window.mrTabs.tabShown).toHaveBeenCalledWith('diffs');
    });
  });
});
