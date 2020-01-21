import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import * as actions from '~/error_tracking_settings/store/actions';
import * as types from '~/error_tracking_settings/store/mutation_types';
import defaultState from '~/error_tracking_settings/store/state';
import { projectList } from '../mock';

jest.mock('~/lib/utils/url_utility');

describe('error tracking settings actions', () => {
  let state;

  describe('project list actions', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
      state = { ...defaultState(), listProjectsEndpoint: TEST_HOST };
    });

    afterEach(() => {
      mock.restore();
      refreshCurrentPage.mockClear();
    });

    it('should request and transform the project list', done => {
      mock.onGet(TEST_HOST).reply(() => [200, { projects: projectList }]);
      testAction(
        actions.fetchProjects,
        null,
        state,
        [],
        [
          { type: 'requestProjects' },
          {
            type: 'receiveProjectsSuccess',
            payload: projectList.map(convertObjectPropsToCamelCase),
          },
        ],
        () => {
          expect(mock.history.get.length).toBe(1);
          done();
        },
      );
    });

    it('should handle a server error', done => {
      mock.onGet(`${TEST_HOST}.json`).reply(() => [400]);
      testAction(
        actions.fetchProjects,
        null,
        state,
        [],
        [
          { type: 'requestProjects' },
          {
            type: 'receiveProjectsError',
          },
        ],
        () => {
          expect(mock.history.get.length).toBe(1);
          done();
        },
      );
    });

    it('should request projects correctly', done => {
      testAction(
        actions.requestProjects,
        null,
        state,
        [{ type: types.SET_PROJECTS_LOADING, payload: true }, { type: types.RESET_CONNECT }],
        [],
        done,
      );
    });

    it('should receive projects correctly', done => {
      const testPayload = [];
      testAction(
        actions.receiveProjectsSuccess,
        testPayload,
        state,
        [
          { type: types.UPDATE_CONNECT_SUCCESS },
          { type: types.RECEIVE_PROJECTS, payload: testPayload },
          { type: types.SET_PROJECTS_LOADING, payload: false },
        ],
        [],
        done,
      );
    });

    it('should handle errors when receiving projects', done => {
      const testPayload = [];
      testAction(
        actions.receiveProjectsError,
        testPayload,
        state,
        [
          { type: types.UPDATE_CONNECT_ERROR },
          { type: types.CLEAR_PROJECTS },
          { type: types.SET_PROJECTS_LOADING, payload: false },
        ],
        [],
        done,
      );
    });
  });

  describe('save changes actions', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
      state = {
        operationsSettingsEndpoint: TEST_HOST,
      };
    });

    afterEach(() => {
      mock.restore();
    });

    it('should save the page', done => {
      mock.onPatch(TEST_HOST).reply(200);
      testAction(actions.updateSettings, null, state, [], [{ type: 'requestSettings' }], () => {
        expect(mock.history.patch.length).toBe(1);
        expect(refreshCurrentPage).toHaveBeenCalled();
        done();
      });
    });

    it('should handle a server error', done => {
      mock.onPatch(TEST_HOST).reply(400);
      testAction(
        actions.updateSettings,
        null,
        state,
        [],
        [
          { type: 'requestSettings' },
          {
            type: 'receiveSettingsError',
            payload: new Error('Request failed with status code 400'),
          },
        ],
        () => {
          expect(mock.history.patch.length).toBe(1);
          done();
        },
      );
    });

    it('should request to save the page', done => {
      testAction(
        actions.requestSettings,
        null,
        state,
        [{ type: types.UPDATE_SETTINGS_LOADING, payload: true }],
        [],
        done,
      );
    });

    it('should handle errors when requesting to save the page', done => {
      testAction(
        actions.receiveSettingsError,
        {},
        state,
        [{ type: types.UPDATE_SETTINGS_LOADING, payload: false }],
        [],
        done,
      );
    });
  });

  describe('generic actions to update the store', () => {
    const testData = 'test';
    it('should reset the `connect success` flag when updating the api host', done => {
      testAction(
        actions.updateApiHost,
        testData,
        state,
        [{ type: types.UPDATE_API_HOST, payload: testData }, { type: types.RESET_CONNECT }],
        [],
        done,
      );
    });

    it('should reset the `connect success` flag when updating the token', done => {
      testAction(
        actions.updateToken,
        testData,
        state,
        [{ type: types.UPDATE_TOKEN, payload: testData }, { type: types.RESET_CONNECT }],
        [],
        done,
      );
    });
  });
});
