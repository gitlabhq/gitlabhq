import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/error_tracking_settings/store/actions';
import * as types from '~/error_tracking_settings/store/mutation_types';
import defaultState from '~/error_tracking_settings/store/state';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
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

    it('should request and transform the project list', async () => {
      mock.onGet(TEST_HOST).reply(() => [HTTP_STATUS_OK, { projects: projectList }]);
      await testAction(
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
      );
      expect(mock.history.get.length).toBe(1);
    });

    it('should handle a server error', async () => {
      mock.onGet(`${TEST_HOST}.json`).reply(() => [HTTP_STATUS_BAD_REQUEST]);
      await testAction(
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
      );
      expect(mock.history.get.length).toBe(1);
    });

    it('should request projects correctly', () => {
      return testAction(
        actions.requestProjects,
        null,
        state,
        [{ type: types.SET_PROJECTS_LOADING, payload: true }, { type: types.RESET_CONNECT }],
        [],
      );
    });

    it('should receive projects correctly', () => {
      const testPayload = [];
      return testAction(
        actions.receiveProjectsSuccess,
        testPayload,
        state,
        [
          { type: types.UPDATE_CONNECT_SUCCESS },
          { type: types.RECEIVE_PROJECTS, payload: testPayload },
          { type: types.SET_PROJECTS_LOADING, payload: false },
        ],
        [],
      );
    });

    it('should handle errors when receiving projects', () => {
      const testPayload = [];
      return testAction(
        actions.receiveProjectsError,
        testPayload,
        state,
        [
          { type: types.UPDATE_CONNECT_ERROR },
          { type: types.CLEAR_PROJECTS },
          { type: types.SET_PROJECTS_LOADING, payload: false },
        ],
        [],
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

    it('should save the page', async () => {
      mock.onPatch(TEST_HOST).reply(HTTP_STATUS_OK);
      await testAction(actions.updateSettings, null, state, [], [{ type: 'requestSettings' }]);
      expect(mock.history.patch.length).toBe(1);
      expect(refreshCurrentPage).toHaveBeenCalled();
    });

    it('should handle a server error', async () => {
      mock.onPatch(TEST_HOST).reply(HTTP_STATUS_BAD_REQUEST);
      await testAction(
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
      );
      expect(mock.history.patch.length).toBe(1);
    });

    it('should request to save the page', () => {
      return testAction(
        actions.requestSettings,
        null,
        state,
        [{ type: types.UPDATE_SETTINGS_LOADING, payload: true }],
        [],
      );
    });

    it('should handle errors when requesting to save the page', () => {
      return testAction(
        actions.receiveSettingsError,
        {},
        state,
        [{ type: types.UPDATE_SETTINGS_LOADING, payload: false }],
        [],
      );
    });
  });

  describe('generic actions to update the store', () => {
    const testData = 'test';
    it('should reset the `connect success` flag when updating the api host', () => {
      return testAction(
        actions.updateApiHost,
        testData,
        state,
        [{ type: types.UPDATE_API_HOST, payload: testData }, { type: types.RESET_CONNECT }],
        [],
      );
    });

    it('should reset the `connect success` flag when updating the token', () => {
      return testAction(
        actions.updateToken,
        testData,
        state,
        [{ type: types.UPDATE_TOKEN, payload: testData }, { type: types.RESET_CONNECT }],
        [],
      );
    });

    it.each([true, false])('should set the `integrated` flag to `%s`', async (payload) => {
      await testAction(actions.updateIntegrated, payload, state, [
        { type: types.UPDATE_INTEGRATED, payload },
      ]);
    });
  });
});
