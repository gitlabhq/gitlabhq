import testAction from 'helpers/vuex_action_helper';
import Api from '~/api';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import * as actions from '~/user_lists/store/new/actions';
import * as types from '~/user_lists/store/new/mutation_types';
import createState from '~/user_lists/store/new/state';
import { userList } from 'jest/feature_flags/mock_data';

jest.mock('~/api');
jest.mock('~/lib/utils/url_utility');

describe('User Lists Edit Actions', () => {
  let state;

  beforeEach(() => {
    state = createState({ projectId: '1' });
  });

  describe('dismissErrorAlert', () => {
    it('should commit DISMISS_ERROR_ALERT', () => {
      return testAction(actions.dismissErrorAlert, undefined, state, [
        { type: types.DISMISS_ERROR_ALERT },
      ]);
    });
  });

  describe('createUserList', () => {
    let createdList;

    beforeEach(() => {
      createdList = {
        ...userList,
        name: 'new',
      };
    });
    describe('success', () => {
      beforeEach(() => {
        Api.createFeatureFlagUserList.mockResolvedValue({ data: userList });
      });

      it('should redirect to the user list page', () => {
        return testAction(actions.createUserList, createdList, state, [], [], () => {
          expect(Api.createFeatureFlagUserList).toHaveBeenCalledWith('1', createdList);
          expect(redirectTo).toHaveBeenCalledWith(userList.path); // eslint-disable-line import/no-deprecated
        });
      });
    });

    describe('error', () => {
      let error;

      beforeEach(() => {
        error = { message: 'error' };
        Api.createFeatureFlagUserList.mockRejectedValue(error);
      });

      it('should commit RECEIVE_USER_LIST_ERROR', () => {
        return testAction(
          actions.createUserList,
          createdList,
          state,
          [{ type: types.RECEIVE_CREATE_USER_LIST_ERROR, payload: ['error'] }],
          [],
          () => expect(Api.createFeatureFlagUserList).toHaveBeenCalledWith('1', createdList),
        );
      });
    });
  });
});
