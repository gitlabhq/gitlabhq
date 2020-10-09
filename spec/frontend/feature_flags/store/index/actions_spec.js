import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';
import Api from '~/api';
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
  requestUserLists,
  receiveUserListsSuccess,
  receiveUserListsError,
  fetchUserLists,
  deleteUserList,
  receiveDeleteUserListError,
  clearAlert,
} from '~/feature_flags/store/index/actions';
import { mapToScopesViewModel } from '~/feature_flags/store/helpers';
import state from '~/feature_flags/store/index/state';
import * as types from '~/feature_flags/store/index/mutation_types';
import axios from '~/lib/utils/axios_utils';
import { getRequestData, rotateData, featureFlag, userList } from '../../mock_data';

jest.mock('~/api.js');

describe('Feature flags actions', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state({});
  });

  describe('setFeatureFlagsOptions', () => {
    it('should commit SET_FEATURE_FLAGS_OPTIONS mutation', done => {
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
      it('dispatches requestFeatureFlags and receiveFeatureFlagsSuccess ', done => {
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
      it('dispatches requestFeatureFlags and receiveFeatureFlagsError ', done => {
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
    it('should commit RECEIVE_FEATURE_FLAGS_SUCCESS mutation', done => {
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
    it('should commit RECEIVE_FEATURE_FLAGS_SUCCESS mutation', done => {
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
    it('should commit RECEIVE_FEATURE_FLAGS_ERROR mutation', done => {
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

  describe('fetchUserLists', () => {
    beforeEach(() => {
      Api.fetchFeatureFlagUserLists.mockResolvedValue({ data: [userList], headers: {} });
    });

    describe('success', () => {
      it('dispatches requestUserLists and receiveUserListsSuccess ', done => {
        testAction(
          fetchUserLists,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestUserLists',
            },
            {
              payload: { data: [userList], headers: {} },
              type: 'receiveUserListsSuccess',
            },
          ],
          done,
        );
      });
    });

    describe('error', () => {
      it('dispatches requestUserLists and receiveUserListsError ', done => {
        Api.fetchFeatureFlagUserLists.mockRejectedValue();

        testAction(
          fetchUserLists,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestUserLists',
            },
            {
              type: 'receiveUserListsError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('requestUserLists', () => {
    it('should commit RECEIVE_USER_LISTS_SUCCESS mutation', done => {
      testAction(
        requestUserLists,
        null,
        mockedState,
        [{ type: types.REQUEST_USER_LISTS }],
        [],
        done,
      );
    });
  });

  describe('receiveUserListsSuccess', () => {
    it('should commit RECEIVE_USER_LISTS_SUCCESS mutation', done => {
      testAction(
        receiveUserListsSuccess,
        { data: [userList], headers: {} },
        mockedState,
        [
          {
            type: types.RECEIVE_USER_LISTS_SUCCESS,
            payload: { data: [userList], headers: {} },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveUserListsError', () => {
    it('should commit RECEIVE_USER_LISTS_ERROR mutation', done => {
      testAction(
        receiveUserListsError,
        null,
        mockedState,
        [{ type: types.RECEIVE_USER_LISTS_ERROR }],
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
      it('dispatches requestRotateInstanceId and receiveRotateInstanceIdSuccess ', done => {
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
      it('dispatches requestRotateInstanceId and receiveRotateInstanceIdError ', done => {
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
    it('should commit REQUEST_ROTATE_INSTANCE_ID mutation', done => {
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
    it('should commit RECEIVE_ROTATE_INSTANCE_ID_SUCCESS mutation', done => {
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
    it('should commit RECEIVE_ROTATE_INSTANCE_ID_ERROR mutation', done => {
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
      mockedState.featureFlags = getRequestData.feature_flags.map(flag => ({
        ...flag,
        scopes: mapToScopesViewModel(flag.scopes || []),
      }));
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });
    describe('success', () => {
      it('dispatches updateFeatureFlag and receiveUpdateFeatureFlagSuccess', done => {
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
      it('dispatches updateFeatureFlag and receiveUpdateFeatureFlagSuccess', done => {
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
      mockedState.featureFlags = getRequestData.feature_flags.map(f => ({
        ...f,
        scopes: mapToScopesViewModel(f.scopes || []),
      }));
    });

    it('commits UPDATE_FEATURE_FLAG with the given flag', done => {
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
      mockedState.featureFlags = getRequestData.feature_flags.map(f => ({
        ...f,
        scopes: mapToScopesViewModel(f.scopes || []),
      }));
    });

    it('commits RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS with the given flag', done => {
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
      mockedState.featureFlags = getRequestData.feature_flags.map(f => ({
        ...f,
        scopes: mapToScopesViewModel(f.scopes || []),
      }));
    });

    it('commits RECEIVE_UPDATE_FEATURE_FLAG_ERROR with the given flag id', done => {
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
  describe('deleteUserList', () => {
    beforeEach(() => {
      mockedState.userLists = [userList];
    });

    describe('success', () => {
      beforeEach(() => {
        Api.deleteFeatureFlagUserList.mockResolvedValue();
      });

      it('should refresh the user lists', done => {
        testAction(
          deleteUserList,
          userList,
          mockedState,
          [],
          [{ type: 'requestDeleteUserList', payload: userList }, { type: 'fetchUserLists' }],
          done,
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        Api.deleteFeatureFlagUserList.mockRejectedValue({ response: { data: 'some error' } });
      });

      it('should dispatch receiveDeleteUserListError', done => {
        testAction(
          deleteUserList,
          userList,
          mockedState,
          [],
          [
            { type: 'requestDeleteUserList', payload: userList },
            {
              type: 'receiveDeleteUserListError',
              payload: { list: userList, error: 'some error' },
            },
          ],
          done,
        );
      });
    });
  });

  describe('receiveDeleteUserListError', () => {
    it('should commit RECEIVE_DELETE_USER_LIST_ERROR with the given list', done => {
      testAction(
        receiveDeleteUserListError,
        { list: userList, error: 'mock error' },
        mockedState,
        [
          {
            type: 'RECEIVE_DELETE_USER_LIST_ERROR',
            payload: { list: userList, error: 'mock error' },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('clearAlert', () => {
    it('should commit RECEIVE_CLEAR_ALERT', done => {
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
