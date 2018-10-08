import Vue from 'vue';
import VueResource from 'vue-resource';
import _ from 'underscore';
import testAction from 'spec/helpers/vuex_action_helper';
import * as actions from 'ee/batch_comments/stores/modules/batch_comments/actions';

Vue.use(VueResource);

describe('Batch comments store actions', () => {
  let interceptor;
  let res = {};
  let status = 200;

  beforeEach(() => {
    interceptor = (request, next) => {
      next(
        request.respondWith(JSON.stringify(res), {
          status,
        }),
      );
    };

    Vue.http.interceptors.push(interceptor);
  });

  afterEach(() => {
    res = {};
    status = 200;

    Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
  });

  describe('enableBatchComments', () => {
    it('commits ENABLE_BATCH_COMMENTS', done => {
      testAction(
        actions.enableBatchComments,
        null,
        null,
        [{ type: 'ENABLE_BATCH_COMMENTS' }],
        [],
        done,
      );
    });
  });

  describe('saveDraft', () => {
    it('dispatches saveNote on root', () => {
      const dispatch = jasmine.createSpy();

      actions.saveDraft({ dispatch }, { id: 1 });

      expect(dispatch).toHaveBeenCalledWith('saveNote', { id: 1, isDraft: true }, { root: true });
    });
  });

  describe('addDraftToDiscussion', () => {
    it('commits ADD_NEW_DRAFT if no errors returned', done => {
      res = { id: 1 };

      testAction(
        actions.addDraftToDiscussion,
        { endpoint: gl.TEST_HOST, data: 'test' },
        null,
        [{ type: 'ADD_NEW_DRAFT', payload: res }],
        [],
        done,
      );
    });

    it('does not commit ADD_NEW_DRAFT if errors returned', done => {
      status = 500;

      testAction(
        actions.addDraftToDiscussion,
        { endpoint: gl.TEST_HOST, data: 'test' },
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

      testAction(
        actions.createNewDraft,
        { endpoint: gl.TEST_HOST, data: 'test' },
        null,
        [{ type: 'ADD_NEW_DRAFT', payload: res }],
        [],
        done,
      );
    });

    it('does not commit ADD_NEW_DRAFT if errors returned', done => {
      status = 500;

      testAction(
        actions.createNewDraft,
        { endpoint: gl.TEST_HOST, data: 'test' },
        null,
        [],
        [],
        done,
      );
    });
  });

  describe('deleteDraft', () => {
    let getters;

    beforeEach(() => {
      getters = {
        getNotesData: {
          draftsDiscardPath: gl.TEST_HOST,
        },
      };
    });

    it('commits DELETE_DRAFT if no errors returned', done => {
      const commit = jasmine.createSpy('commit');
      const context = {
        getters,
        commit,
      };
      res = { id: 1 };

      actions
        .deleteDraft(context, { id: 1 })
        .then(() => {
          expect(commit).toHaveBeenCalledWith('DELETE_DRAFT', 1);
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not commit DELETE_DRAFT if errors returned', done => {
      const commit = jasmine.createSpy('commit');
      const context = {
        getters,
        commit,
      };
      res = '';
      status = '500';

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
          draftsPath: gl.TEST_HOST,
        },
      };
    });

    it('commits SET_BATCH_COMMENTS_DRAFTS with returned data', done => {
      const commit = jasmine.createSpy('commit');
      const context = {
        getters,
        commit,
      };
      res = { id: 1 };

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
      dispatch = jasmine.createSpy('dispatch');
      commit = jasmine.createSpy('commit');
      getters = {
        getNotesData: { draftsPublishPath: gl.TEST_HOST, discussionsPath: gl.TEST_HOST },
      };
      rootGetters = { discussionsStructuredByLineCode: 'discussions' };
    });

    it('dispatches actions & commits', done => {
      actions
        .publishReview({ dispatch, commit, getters, rootGetters })
        .then(() => {
          expect(commit.calls.argsFor(0)).toEqual(['REQUEST_PUBLISH_REVIEW']);
          expect(commit.calls.argsFor(1)).toEqual(['RECEIVE_PUBLISH_REVIEW_SUCCESS']);

          expect(dispatch.calls.argsFor(0)).toEqual(['updateDiscussionsAfterPublish']);
        })
        .then(done)
        .catch(done.fail);
    });

    it('dispatches error commits', done => {
      status = 500;

      actions
        .publishReview({ dispatch, commit, getters, rootGetters })
        .then(() => {
          expect(commit.calls.argsFor(0)).toEqual(['REQUEST_PUBLISH_REVIEW']);
          expect(commit.calls.argsFor(1)).toEqual(['RECEIVE_PUBLISH_REVIEW_ERROR']);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('discardReview', () => {
    it('commits mutations', done => {
      const getters = {
        getNotesData: { draftsDiscardPath: gl.TEST_HOST },
      };
      const commit = jasmine.createSpy('commit');

      actions
        .discardReview({ getters, commit })
        .then(() => {
          expect(commit.calls.argsFor(0)).toEqual(['REQUEST_DISCARD_REVIEW']);
          expect(commit.calls.argsFor(1)).toEqual(['RECEIVE_DISCARD_REVIEW_SUCCESS']);
        })
        .then(done)
        .catch(done.fail);
    });

    it('commits error mutations', done => {
      const getters = {
        getNotesData: { draftsDiscardPath: gl.TEST_HOST },
      };
      const commit = jasmine.createSpy('commit');

      status = 500;

      actions
        .discardReview({ getters, commit })
        .then(() => {
          expect(commit.calls.argsFor(0)).toEqual(['REQUEST_DISCARD_REVIEW']);
          expect(commit.calls.argsFor(1)).toEqual(['RECEIVE_DISCARD_REVIEW_ERROR']);
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
          draftsPath: gl.TEST_HOST,
        },
      };
    });

    it('commits RECEIVE_DRAFT_UPDATE_SUCCESS with returned data', done => {
      const commit = jasmine.createSpy('commit');
      const context = {
        getters,
        commit,
      };
      res = { id: 1 };

      actions
        .updateDraft(context, { note: { id: 1 }, noteText: 'test', callback() {} })
        .then(() => {
          expect(commit).toHaveBeenCalledWith('RECEIVE_DRAFT_UPDATE_SUCCESS', { id: 1 });
        })
        .then(done)
        .catch(done.fail);
    });

    it('calls passed callback', done => {
      const commit = jasmine.createSpy('commit');
      const context = {
        getters,
        commit,
      };
      const callback = jasmine.createSpy('callback');
      res = { id: 1 };

      actions
        .updateDraft(context, { note: { id: 1 }, noteText: 'test', callback })
        .then(() => {
          expect(callback).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
