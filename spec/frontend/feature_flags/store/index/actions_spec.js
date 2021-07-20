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
import { getRequestData, rotateData, featureFlag } from '../../mock_data';

jest.mock('~/api.js');

describe('Feature flags actions', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state({});
  });

  describe('setFeatureFlagsOptions', () => {
    it('should commit SET_FEATURE_FLAGS_OPTIONS mutation', (done) => {
      testAction(
        setFeatureFlagsOptions,
        { page: '1', scope: 'all' },
        mockedState,
        [{ type: types.SET_FEATURE_FLAGS_OPTIONS, payload: { page: '1', scope: 'all' } }],
        [],
        done,
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
      it('dispatches requestFeatureFlags and receiveFeatureFlagsSuccess ', (done) => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).replyOnce(200, getRequestData, {});

        testAction(
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
          done,
        );
      });
    });

    describe('error', () => {
      it('dispatches requestFeatureFlags and receiveFeatureFlagsError ', (done) => {
        mock.onGet(`${TEST_HOST}/endpoint.json`, {}).replyOnce(500, {});

        testAction(
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
          done,
        );
      });
    });
  });

  describe('requestFeatureFlags', () => {
    it('should commit RECEIVE_FEATURE_FLAGS_SUCCESS mutation', (done) => {
      testAction(
        requestFeatureFlags,
        null,
        mockedState,
        [{ type: types.REQUEST_FEATURE_FLAGS }],
        [],
        done,
      );
    });
  });

  describe('receiveFeatureFlagsSuccess', () => {
    it('should commit RECEIVE_FEATURE_FLAGS_SUCCESS mutation', (done) => {
      testAction(
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
        done,
      );
    });
  });

  describe('receiveFeatureFlagsError', () => {
    it('should commit RECEIVE_FEATURE_FLAGS_ERROR mutation', (done) => {
      testAction(
        receiveFeatureFlagsError,
        null,
        mockedState,
        [{ type: types.RECEIVE_FEATURE_FLAGS_ERROR }],
        [],
        done,
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
      it('dispatches requestRotateInstanceId and receiveRotateInstanceIdSuccess ', (done) => {
        mock.onPost(`${TEST_HOST}/endpoint.json`).replyOnce(200, rotateData, {});

        testAction(
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
          done,
        );
      });
    });

    describe('error', () => {
      it('dispatches requestRotateInstanceId and receiveRotateInstanceIdError ', (done) => {
        mock.onGet(`${TEST_HOST}/endpoint.json`, {}).replyOnce(500, {});

        testAction(
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
          done,
        );
      });
    });
  });

  describe('requestRotateInstanceId', () => {
    it('should commit REQUEST_ROTATE_INSTANCE_ID mutation', (done) => {
      testAction(
        requestRotateInstanceId,
        null,
        mockedState,
        [{ type: types.REQUEST_ROTATE_INSTANCE_ID }],
        [],
        done,
      );
    });
  });

  describe('receiveRotateInstanceIdSuccess', () => {
    it('should commit RECEIVE_ROTATE_INSTANCE_ID_SUCCESS mutation', (done) => {
      testAction(
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
        done,
      );
    });
  });

  describe('receiveRotateInstanceIdError', () => {
    it('should commit RECEIVE_ROTATE_INSTANCE_ID_ERROR mutation', (done) => {
      testAction(
        receiveRotateInstanceIdError,
        null,
        mockedState,
        [{ type: types.RECEIVE_ROTATE_INSTANCE_ID_ERROR }],
        [],
        done,
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
      it('dispatches updateFeatureFlag and receiveUpdateFeatureFlagSuccess', (done) => {
        mock.onPut(featureFlag.update_path).replyOnce(200, featureFlag, {});

        testAction(
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
          done,
        );
      });
    });
    describe('error', () => {
      it('dispatches updateFeatureFlag and receiveUpdateFeatureFlagSuccess', (done) => {
        mock.onPut(featureFlag.update_path).replyOnce(500);

        testAction(
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
          done,
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

    it('commits UPDATE_FEATURE_FLAG with the given flag', (done) => {
      testAction(
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
        done,
      );
    });
  });
  describe('receiveUpdateFeatureFlagSuccess', () => {
    beforeEach(() => {
      mockedState.featureFlags = getRequestData.feature_flags.map((f) => ({
        ...f,
      }));
    });

    it('commits RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS with the given flag', (done) => {
      testAction(
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
        done,
      );
    });
  });
  describe('receiveUpdateFeatureFlagError', () => {
    beforeEach(() => {
      mockedState.featureFlags = getRequestData.feature_flags.map((f) => ({
        ...f,
      }));
    });

    it('commits RECEIVE_UPDATE_FEATURE_FLAG_ERROR with the given flag id', (done) => {
      testAction(
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
        done,
      );
    });
  });

  describe('clearAlert', () => {
    it('should commit RECEIVE_CLEAR_ALERT', (done) => {
      const alertIndex = 3;

      testAction(
        clearAlert,
        alertIndex,
        mockedState,
        [{ type: 'RECEIVE_CLEAR_ALERT', payload: alertIndex }],
        [],
        done,
      );
    });
  });
});
