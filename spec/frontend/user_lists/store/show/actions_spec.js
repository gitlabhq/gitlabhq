import testAction from 'helpers/vuex_action_helper';
import { userList } from 'jest/feature_flags/mock_data';
import Api from '~/api';
import * as actions from '~/user_lists/store/show/actions';
import * as types from '~/user_lists/store/show/mutation_types';
import createState from '~/user_lists/store/show/state';
import { stringifyUserIds } from '~/user_lists/store/utils';

jest.mock('~/api');

describe('User Lists Show Actions', () => {
  let mockState;

  beforeEach(() => {
    mockState = createState({ projectId: '1', userListIid: '2' });
  });

  describe('fetchUserList', () => {
    it('commits REQUEST_USER_LIST and RECEIVE_USER_LIST_SUCCESS on success', async () => {
      Api.fetchFeatureFlagUserList.mockResolvedValue({ data: userList });
      await testAction(
        actions.fetchUserList,
        undefined,
        mockState,
        [
          { type: types.REQUEST_USER_LIST },
          { type: types.RECEIVE_USER_LIST_SUCCESS, payload: userList },
        ],
        [],
      );
      expect(Api.fetchFeatureFlagUserList).toHaveBeenCalledWith('1', '2');
    });

    it('commits REQUEST_USER_LIST and RECEIVE_USER_LIST_ERROR on error', () => {
      Api.fetchFeatureFlagUserList.mockRejectedValue({ message: 'fail' });
      return testAction(
        actions.fetchUserList,
        undefined,
        mockState,
        [{ type: types.REQUEST_USER_LIST }, { type: types.RECEIVE_USER_LIST_ERROR }],
        [],
      );
    });
  });

  describe('dismissErrorAlert', () => {
    it('commits DISMISS_ERROR_ALERT', () => {
      return testAction(
        actions.dismissErrorAlert,
        undefined,
        mockState,
        [{ type: types.DISMISS_ERROR_ALERT }],
        [],
      );
    });
  });

  describe('addUserIds', () => {
    it('adds the given IDs and tries to update the user list', () => {
      return testAction(
        actions.addUserIds,
        '1,2,3',
        mockState,
        [{ type: types.ADD_USER_IDS, payload: '1,2,3' }],
        [{ type: 'updateUserList' }],
      );
    });
  });

  describe('removeUserId', () => {
    it('removes the given ID and tries to update the user list', () => {
      return testAction(
        actions.removeUserId,
        'user3',
        mockState,
        [{ type: types.REMOVE_USER_ID, payload: 'user3' }],
        [{ type: 'updateUserList' }],
      );
    });
  });

  describe('updateUserList', () => {
    beforeEach(() => {
      mockState.userList = userList;
      mockState.userIds = ['user1', 'user2', 'user3'];
    });

    it('commits REQUEST_USER_LIST and RECEIVE_USER_LIST_SUCCESS on success', async () => {
      Api.updateFeatureFlagUserList.mockResolvedValue({ data: userList });
      await testAction(
        actions.updateUserList,
        undefined,
        mockState,
        [
          { type: types.REQUEST_USER_LIST },
          { type: types.RECEIVE_USER_LIST_SUCCESS, payload: userList },
        ],
        [],
      );
      expect(Api.updateFeatureFlagUserList).toHaveBeenCalledWith('1', {
        ...userList,
        user_xids: stringifyUserIds(mockState.userIds),
      });
    });
    it('commits REQUEST_USER_LIST and RECEIVE_USER_LIST_ERROR on error', () => {
      Api.updateFeatureFlagUserList.mockRejectedValue({ message: 'fail' });
      return testAction(
        actions.updateUserList,
        undefined,
        mockState,
        [{ type: types.REQUEST_USER_LIST }, { type: types.RECEIVE_USER_LIST_ERROR }],
        [],
      );
    });
  });
});
