import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import * as actions from '~/registry/list/stores/actions';
import * as types from '~/registry/list/stores/mutation_types';
import createFlash from '~/flash';

import {
  reposServerResponse,
  registryServerResponse,
  parsedReposServerResponse,
} from '../mock_data';

jest.mock('~/flash.js');

describe('Actions Registry Store', () => {
  let mock;
  let state;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    state = {
      endpoint: `${TEST_HOST}/endpoint.json`,
    };
  });

  afterEach(() => {
    mock.restore();
  });

  describe('fetchRepos', () => {
    beforeEach(() => {
      mock.onGet(`${TEST_HOST}/endpoint.json`).replyOnce(200, reposServerResponse, {});
    });

    it('should set received repos', done => {
      testAction(
        actions.fetchRepos,
        null,
        state,
        [
          { type: types.TOGGLE_MAIN_LOADING },
          { type: types.TOGGLE_MAIN_LOADING },
          { type: types.SET_REPOS_LIST, payload: reposServerResponse },
        ],
        [],
        done,
      );
    });

    it('should create flash on API error', done => {
      testAction(
        actions.fetchRepos,
        null,
        {
          endpoint: null,
        },
        [{ type: types.TOGGLE_MAIN_LOADING }, { type: types.TOGGLE_MAIN_LOADING }],
        [],
        () => {
          expect(createFlash).toHaveBeenCalled();
          done();
        },
      );
    });
  });

  describe('fetchList', () => {
    let repo;
    beforeEach(() => {
      state.repos = parsedReposServerResponse;
      [, repo] = state.repos;
    });

    it('should set received list', done => {
      mock.onGet(repo.tagsPath).replyOnce(200, registryServerResponse, {});
      testAction(
        actions.fetchList,
        { repo },
        state,
        [
          { type: types.TOGGLE_REGISTRY_LIST_LOADING, payload: repo },
          { type: types.TOGGLE_REGISTRY_LIST_LOADING, payload: repo },
          {
            type: types.SET_REGISTRY_LIST,
            payload: {
              repo,
              resp: registryServerResponse,
              headers: expect.anything(),
            },
          },
        ],
        [],
        done,
      );
    });

    it('should create flash on API error', done => {
      mock.onGet(repo.tagsPath).replyOnce(400);
      const updatedRepo = {
        ...repo,
        tagsPath: null,
      };
      testAction(
        actions.fetchList,
        {
          repo: updatedRepo,
        },
        state,
        [
          { type: types.TOGGLE_REGISTRY_LIST_LOADING, payload: updatedRepo },
          { type: types.TOGGLE_REGISTRY_LIST_LOADING, payload: updatedRepo },
        ],
        [],
        () => {
          expect(createFlash).toHaveBeenCalled();
          done();
        },
      );
    });
  });

  describe('setMainEndpoint', () => {
    it('should commit set main endpoint', done => {
      testAction(
        actions.setMainEndpoint,
        'endpoint',
        state,
        [{ type: types.SET_MAIN_ENDPOINT, payload: 'endpoint' }],
        [],
        done,
      );
    });
  });

  describe('setIsDeleteDisabled', () => {
    it('should commit set is delete disabled', done => {
      testAction(
        actions.setIsDeleteDisabled,
        true,
        state,
        [{ type: types.SET_IS_DELETE_DISABLED, payload: true }],
        [],
        done,
      );
    });
  });

  describe('toggleLoading', () => {
    it('should commit toggle main loading', done => {
      testAction(
        actions.toggleLoading,
        null,
        state,
        [{ type: types.TOGGLE_MAIN_LOADING }],
        [],
        done,
      );
    });
  });

  describe('deleteItem and multiDeleteItems', () => {
    let deleted;
    const destroyPath = `${TEST_HOST}/mygroup/myproject/container_registry/1.json`;

    const expectDelete = done => {
      expect(mock.history.delete.length).toBe(1);
      expect(deleted).toBe(true);
      done();
    };

    beforeEach(() => {
      deleted = false;
      mock.onDelete(destroyPath).replyOnce(() => {
        deleted = true;
        return [200];
      });
    });

    it('deleteItem should perform DELETE request on destroyPath', done => {
      testAction(
        actions.deleteItem,
        {
          destroyPath,
        },
        state,
      )
        .then(() => {
          expectDelete(done);
        })
        .catch(done.fail);
    });

    it('multiDeleteItems should perform DELETE request on path', done => {
      testAction(actions.multiDeleteItems, { path: destroyPath, items: [1] }, state)
        .then(() => {
          expectDelete(done);
        })
        .catch(done.fail);
    });
  });
});
