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
import { userList } from '../../../feature_flags/mock_data';

jest.mock('~/api.js');

describe('~/user_lists/store/index/actions', () => {
  let state;

  beforeEach(() => {
    state = createState({ projectId: '1' });
  });

  describe('setUserListsOptions', () => {
    it('should commit SET_USER_LISTS_OPTIONS mutation', (done) => {
      testAction(
        setUserListsOptions,
        { page: '1', scope: 'all' },
        state,
        [{ type: types.SET_USER_LISTS_OPTIONS, payload: { page: '1', scope: 'all' } }],
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
      it('dispatches requestUserLists and receiveUserListsSuccess ', (done) => {
        testAction(
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
          done,
        );
      });
    });

    describe('error', () => {
      it('dispatches requestUserLists and receiveUserListsError ', (done) => {
        Api.fetchFeatureFlagUserLists.mockRejectedValue();

        testAction(
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
          done,
        );
      });
    });
  });

  describe('requestUserLists', () => {
    it('should commit RECEIVE_USER_LISTS_SUCCESS mutation', (done) => {
      testAction(requestUserLists, null, state, [{ type: types.REQUEST_USER_LISTS }], [], done);
    });
  });

  describe('receiveUserListsSuccess', () => {
    it('should commit RECEIVE_USER_LISTS_SUCCESS mutation', (done) => {
      testAction(
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
        done,
      );
    });
  });

  describe('receiveUserListsError', () => {
    it('should commit RECEIVE_USER_LISTS_ERROR mutation', (done) => {
      testAction(
        receiveUserListsError,
        null,
        state,
        [{ type: types.RECEIVE_USER_LISTS_ERROR }],
        [],
        done,
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

      it('should refresh the user lists', (done) => {
        testAction(
          deleteUserList,
          userList,
          state,
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

      it('should dispatch receiveDeleteUserListError', (done) => {
        testAction(
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
          done,
        );
      });
    });
  });

  describe('receiveDeleteUserListError', () => {
    it('should commit RECEIVE_DELETE_USER_LIST_ERROR with the given list', (done) => {
      testAction(
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
        state,
        [{ type: 'RECEIVE_CLEAR_ALERT', payload: alertIndex }],
        [],
        done,
      );
    });
  });
});
