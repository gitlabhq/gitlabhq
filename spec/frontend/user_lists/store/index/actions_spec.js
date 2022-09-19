import testAction from 'helpers/vuex_action_helper';
import Api from '~/api';
import {
  setUserListsOptions,
  requestUserLists,
  receiveUserListsSuccess,
  receiveUserListsError,
  fetchUserLists,
  deleteUserList,
  receiveDeleteUserListError,
  clearAlert,
} from '~/user_lists/store/index/actions';
import * as types from '~/user_lists/store/index/mutation_types';
import createState from '~/user_lists/store/index/state';
import { userList } from 'jest/feature_flags/mock_data';

jest.mock('~/api.js');

describe('~/user_lists/store/index/actions', () => {
  let state;

  beforeEach(() => {
    state = createState({ projectId: '1' });
  });

  describe('setUserListsOptions', () => {
    it('should commit SET_USER_LISTS_OPTIONS mutation', () => {
      return testAction(
        setUserListsOptions,
        { page: '1', scope: 'all' },
        state,
        [{ type: types.SET_USER_LISTS_OPTIONS, payload: { page: '1', scope: 'all' } }],
        [],
      );
    });
  });

  describe('fetchUserLists', () => {
    beforeEach(() => {
      Api.fetchFeatureFlagUserLists.mockResolvedValue({ data: [userList], headers: {} });
    });

    describe('success', () => {
      it('dispatches requestUserLists and receiveUserListsSuccess', () => {
        return testAction(
          fetchUserLists,
          null,
          state,
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
        );
      });
    });

    describe('error', () => {
      it('dispatches requestUserLists and receiveUserListsError', () => {
        Api.fetchFeatureFlagUserLists.mockRejectedValue();

        return testAction(
          fetchUserLists,
          null,
          state,
          [],
          [
            {
              type: 'requestUserLists',
            },
            {
              type: 'receiveUserListsError',
            },
          ],
        );
      });
    });
  });

  describe('requestUserLists', () => {
    it('should commit RECEIVE_USER_LISTS_SUCCESS mutation', () => {
      return testAction(requestUserLists, null, state, [{ type: types.REQUEST_USER_LISTS }], []);
    });
  });

  describe('receiveUserListsSuccess', () => {
    it('should commit RECEIVE_USER_LISTS_SUCCESS mutation', () => {
      return testAction(
        receiveUserListsSuccess,
        { data: [userList], headers: {} },
        state,
        [
          {
            type: types.RECEIVE_USER_LISTS_SUCCESS,
            payload: { data: [userList], headers: {} },
          },
        ],
        [],
      );
    });
  });

  describe('receiveUserListsError', () => {
    it('should commit RECEIVE_USER_LISTS_ERROR mutation', () => {
      return testAction(
        receiveUserListsError,
        null,
        state,
        [{ type: types.RECEIVE_USER_LISTS_ERROR }],
        [],
      );
    });
  });

  describe('deleteUserList', () => {
    beforeEach(() => {
      state.userLists = [userList];
    });

    describe('success', () => {
      beforeEach(() => {
        Api.deleteFeatureFlagUserList.mockResolvedValue();
      });

      it('should refresh the user lists', () => {
        return testAction(
          deleteUserList,
          userList,
          state,
          [],
          [{ type: 'requestDeleteUserList', payload: userList }, { type: 'fetchUserLists' }],
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        Api.deleteFeatureFlagUserList.mockRejectedValue({ response: { data: 'some error' } });
      });

      it('should dispatch receiveDeleteUserListError', () => {
        return testAction(
          deleteUserList,
          userList,
          state,
          [],
          [
            { type: 'requestDeleteUserList', payload: userList },
            {
              type: 'receiveDeleteUserListError',
              payload: { list: userList, error: 'some error' },
            },
          ],
        );
      });
    });
  });

  describe('receiveDeleteUserListError', () => {
    it('should commit RECEIVE_DELETE_USER_LIST_ERROR with the given list', () => {
      return testAction(
        receiveDeleteUserListError,
        { list: userList, error: 'mock error' },
        state,
        [
          {
            type: 'RECEIVE_DELETE_USER_LIST_ERROR',
            payload: { list: userList, error: 'mock error' },
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
        state,
        [{ type: 'RECEIVE_CLEAR_ALERT', payload: alertIndex }],
        [],
      );
    });
  });
});
