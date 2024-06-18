import testAction from 'helpers/vuex_action_helper';
import Api from '~/api';
import { visitUrl } from '~/lib/utils/url_utility';
import * as actions from '~/user_lists/store/edit/actions';
import * as types from '~/user_lists/store/edit/mutation_types';
import createState from '~/user_lists/store/edit/state';
import { userList } from 'jest/feature_flags/mock_data';

jest.mock('~/api');
jest.mock('~/lib/utils/url_utility');

describe('User Lists Edit Actions', () => {
  let state;

  beforeEach(() => {
    state = createState({ projectId: '1', userListIid: '2' });
  });

  describe('fetchUserList', () => {
    describe('success', () => {
      beforeEach(() => {
        Api.fetchFeatureFlagUserList.mockResolvedValue({ data: userList });
      });

      it('should commit RECEIVE_USER_LIST_SUCCESS', async () => {
        await testAction(
          actions.fetchUserList,
          undefined,
          state,
          [
            { type: types.REQUEST_USER_LIST },
            { type: types.RECEIVE_USER_LIST_SUCCESS, payload: userList },
          ],
          [],
        );
        expect(Api.fetchFeatureFlagUserList).toHaveBeenCalledWith('1', '2');
      });
    });

    describe('error', () => {
      let error;
      beforeEach(() => {
        error = { response: { data: { message: ['error'] } } };
        Api.fetchFeatureFlagUserList.mockRejectedValue(error);
      });

      it('should commit RECEIVE_USER_LIST_ERROR', async () => {
        await testAction(
          actions.fetchUserList,
          undefined,
          state,
          [
            { type: types.REQUEST_USER_LIST },
            { type: types.RECEIVE_USER_LIST_ERROR, payload: ['error'] },
          ],
          [],
        );
        expect(Api.fetchFeatureFlagUserList).toHaveBeenCalledWith('1', '2');
      });
    });
  });

  describe('dismissErrorAlert', () => {
    it('should commit DISMISS_ERROR_ALERT', () => {
      return testAction(actions.dismissErrorAlert, undefined, state, [
        { type: types.DISMISS_ERROR_ALERT },
      ]);
    });
  });

  describe('updateUserList', () => {
    let updatedList;

    beforeEach(() => {
      updatedList = {
        ...userList,
        name: 'new',
      };
    });
    describe('success', () => {
      beforeEach(() => {
        Api.updateFeatureFlagUserList.mockResolvedValue({ data: userList });
        state.userList = userList;
      });

      it('should commit RECEIVE_USER_LIST_SUCCESS', async () => {
        await testAction(actions.updateUserList, updatedList, state, [], []);
        expect(Api.updateFeatureFlagUserList).toHaveBeenCalledWith('1', {
          name: updatedList.name,
          iid: updatedList.iid,
        });
        expect(visitUrl).toHaveBeenCalledWith(userList.path);
      });
    });

    describe('error', () => {
      let error;

      beforeEach(() => {
        error = { message: 'error' };
        Api.updateFeatureFlagUserList.mockRejectedValue(error);
      });

      it('should commit RECEIVE_USER_LIST_ERROR', async () => {
        await testAction(
          actions.updateUserList,
          updatedList,
          state,
          [{ type: types.RECEIVE_USER_LIST_ERROR, payload: ['error'] }],
          [],
        );
        expect(Api.updateFeatureFlagUserList).toHaveBeenCalledWith('1', {
          name: updatedList.name,
          iid: updatedList.iid,
        });
      });
    });
  });
});
