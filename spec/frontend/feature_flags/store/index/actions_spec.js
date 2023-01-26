import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';
import {
  requestFeatureFlags,
  receiveFeatureFlagsSuccess,
  receiveFeatureFlagsError,
  fetchFeatureFlags,
  setFeatureFlagsOptions,
  rotateInstanceId,
  requestRotateInstanceId,
  receiveRotateInstanceIdSuccess,
  receiveRotateInstanceIdError,
  toggleFeatureFlag,
  updateFeatureFlag,
  receiveUpdateFeatureFlagSuccess,
  receiveUpdateFeatureFlagError,
  clearAlert,
} from '~/feature_flags/store/index/actions';
import * as types from '~/feature_flags/store/index/mutation_types';
import state from '~/feature_flags/store/index/state';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { getRequestData, rotateData, featureFlag } from '../../mock_data';

jest.mock('~/api.js');

describe('Feature flags actions', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state({});
  });

  describe('setFeatureFlagsOptions', () => {
    it('should commit SET_FEATURE_FLAGS_OPTIONS mutation', () => {
      return testAction(
        setFeatureFlagsOptions,
        { page: '1', scope: 'all' },
        mockedState,
        [{ type: types.SET_FEATURE_FLAGS_OPTIONS, payload: { page: '1', scope: 'all' } }],
        [],
      );
    });
  });

  describe('fetchFeatureFlags', () => {
    let mock;

    beforeEach(() => {
      mockedState.endpoint = `${TEST_HOST}/endpoint.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('dispatches requestFeatureFlags and receiveFeatureFlagsSuccess', () => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).replyOnce(HTTP_STATUS_OK, getRequestData, {});

        return testAction(
          fetchFeatureFlags,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestFeatureFlags',
            },
            {
              payload: { data: getRequestData, headers: {} },
              type: 'receiveFeatureFlagsSuccess',
            },
          ],
        );
      });
    });

    describe('error', () => {
      it('dispatches requestFeatureFlags and receiveFeatureFlagsError', () => {
        mock
          .onGet(`${TEST_HOST}/endpoint.json`, {})
          .replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});

        return testAction(
          fetchFeatureFlags,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestFeatureFlags',
            },
            {
              type: 'receiveFeatureFlagsError',
            },
          ],
        );
      });
    });
  });

  describe('requestFeatureFlags', () => {
    it('should commit RECEIVE_FEATURE_FLAGS_SUCCESS mutation', () => {
      return testAction(
        requestFeatureFlags,
        null,
        mockedState,
        [{ type: types.REQUEST_FEATURE_FLAGS }],
        [],
      );
    });
  });

  describe('receiveFeatureFlagsSuccess', () => {
    it('should commit RECEIVE_FEATURE_FLAGS_SUCCESS mutation', () => {
      return testAction(
        receiveFeatureFlagsSuccess,
        { data: getRequestData, headers: {} },
        mockedState,
        [
          {
            type: types.RECEIVE_FEATURE_FLAGS_SUCCESS,
            payload: { data: getRequestData, headers: {} },
          },
        ],
        [],
      );
    });
  });

  describe('receiveFeatureFlagsError', () => {
    it('should commit RECEIVE_FEATURE_FLAGS_ERROR mutation', () => {
      return testAction(
        receiveFeatureFlagsError,
        null,
        mockedState,
        [{ type: types.RECEIVE_FEATURE_FLAGS_ERROR }],
        [],
      );
    });
  });

  describe('rotateInstanceId', () => {
    let mock;

    beforeEach(() => {
      mockedState.rotateEndpoint = `${TEST_HOST}/endpoint.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('dispatches requestRotateInstanceId and receiveRotateInstanceIdSuccess', () => {
        mock.onPost(`${TEST_HOST}/endpoint.json`).replyOnce(HTTP_STATUS_OK, rotateData, {});

        return testAction(
          rotateInstanceId,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestRotateInstanceId',
            },
            {
              payload: { data: rotateData, headers: {} },
              type: 'receiveRotateInstanceIdSuccess',
            },
          ],
        );
      });
    });

    describe('error', () => {
      it('dispatches requestRotateInstanceId and receiveRotateInstanceIdError', () => {
        mock
          .onGet(`${TEST_HOST}/endpoint.json`, {})
          .replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});

        return testAction(
          rotateInstanceId,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestRotateInstanceId',
            },
            {
              type: 'receiveRotateInstanceIdError',
            },
          ],
        );
      });
    });
  });

  describe('requestRotateInstanceId', () => {
    it('should commit REQUEST_ROTATE_INSTANCE_ID mutation', () => {
      return testAction(
        requestRotateInstanceId,
        null,
        mockedState,
        [{ type: types.REQUEST_ROTATE_INSTANCE_ID }],
        [],
      );
    });
  });

  describe('receiveRotateInstanceIdSuccess', () => {
    it('should commit RECEIVE_ROTATE_INSTANCE_ID_SUCCESS mutation', () => {
      return testAction(
        receiveRotateInstanceIdSuccess,
        { data: rotateData, headers: {} },
        mockedState,
        [
          {
            type: types.RECEIVE_ROTATE_INSTANCE_ID_SUCCESS,
            payload: { data: rotateData, headers: {} },
          },
        ],
        [],
      );
    });
  });

  describe('receiveRotateInstanceIdError', () => {
    it('should commit RECEIVE_ROTATE_INSTANCE_ID_ERROR mutation', () => {
      return testAction(
        receiveRotateInstanceIdError,
        null,
        mockedState,
        [{ type: types.RECEIVE_ROTATE_INSTANCE_ID_ERROR }],
        [],
      );
    });
  });

  describe('toggleFeatureFlag', () => {
    let mock;

    beforeEach(() => {
      mockedState.featureFlags = getRequestData.feature_flags.map((flag) => ({
        ...flag,
      }));
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });
    describe('success', () => {
      it('dispatches updateFeatureFlag and receiveUpdateFeatureFlagSuccess', () => {
        mock.onPut(featureFlag.update_path).replyOnce(HTTP_STATUS_OK, featureFlag, {});

        return testAction(
          toggleFeatureFlag,
          featureFlag,
          mockedState,
          [],
          [
            {
              type: 'updateFeatureFlag',
              payload: featureFlag,
            },
            {
              payload: featureFlag,
              type: 'receiveUpdateFeatureFlagSuccess',
            },
          ],
        );
      });
    });

    describe('error', () => {
      it('dispatches updateFeatureFlag and receiveUpdateFeatureFlagSuccess', () => {
        mock.onPut(featureFlag.update_path).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        return testAction(
          toggleFeatureFlag,
          featureFlag,
          mockedState,
          [],
          [
            {
              type: 'updateFeatureFlag',
              payload: featureFlag,
            },
            {
              payload: featureFlag.id,
              type: 'receiveUpdateFeatureFlagError',
            },
          ],
        );
      });
    });
  });
  describe('updateFeatureFlag', () => {
    beforeEach(() => {
      mockedState.featureFlags = getRequestData.feature_flags.map((f) => ({
        ...f,
      }));
    });

    it('commits UPDATE_FEATURE_FLAG with the given flag', () => {
      return testAction(
        updateFeatureFlag,
        featureFlag,
        mockedState,
        [
          {
            type: 'UPDATE_FEATURE_FLAG',
            payload: featureFlag,
          },
        ],
        [],
      );
    });
  });
  describe('receiveUpdateFeatureFlagSuccess', () => {
    beforeEach(() => {
      mockedState.featureFlags = getRequestData.feature_flags.map((f) => ({
        ...f,
      }));
    });

    it('commits RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS with the given flag', () => {
      return testAction(
        receiveUpdateFeatureFlagSuccess,
        featureFlag,
        mockedState,
        [
          {
            type: 'RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS',
            payload: featureFlag,
          },
        ],
        [],
      );
    });
  });
  describe('receiveUpdateFeatureFlagError', () => {
    beforeEach(() => {
      mockedState.featureFlags = getRequestData.feature_flags.map((f) => ({
        ...f,
      }));
    });

    it('commits RECEIVE_UPDATE_FEATURE_FLAG_ERROR with the given flag id', () => {
      return testAction(
        receiveUpdateFeatureFlagError,
        featureFlag.id,
        mockedState,
        [
          {
            type: 'RECEIVE_UPDATE_FEATURE_FLAG_ERROR',
            payload: featureFlag.id,
          },
        ],
        [],
      );
    });
  });

  describe('clearAlert', () => {
    it('should commit RECEIVE_CLEAR_ALERT', () => {
      const alertIndex = 3;

      return testAction(
        clearAlert,
        alertIndex,
        mockedState,
        [{ type: 'RECEIVE_CLEAR_ALERT', payload: alertIndex }],
        [],
      );
    });
  });
});
