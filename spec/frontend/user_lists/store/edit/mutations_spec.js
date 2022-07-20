import statuses from '~/user_lists/constants/edit';
import * as types from '~/user_lists/store/edit/mutation_types';
import mutations from '~/user_lists/store/edit/mutations';
import createState from '~/user_lists/store/edit/state';
import { userList } from 'jest/feature_flags/mock_data';

describe('User List Edit Mutations', () => {
  let state;

  beforeEach(() => {
    state = createState({ projectId: '1', userListIid: '2' });
  });

  describe(types.REQUEST_USER_LIST, () => {
    beforeEach(() => {
      mutations[types.REQUEST_USER_LIST](state);
    });

    it('sets the state to loading', () => {
      expect(state.status).toBe(statuses.LOADING);
    });
  });

  describe(types.RECEIVE_USER_LIST_SUCCESS, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_USER_LIST_SUCCESS](state, userList);
    });

    it('sets the state to success', () => {
      expect(state.status).toBe(statuses.SUCCESS);
    });

    it('sets the user list to the one received', () => {
      expect(state.userList).toEqual(userList);
    });
  });

  describe(types.RECEIVE_USER_LIST_ERROR, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_USER_LIST_ERROR](state, ['network error']);
    });

    it('sets the state to error', () => {
      expect(state.status).toBe(statuses.ERROR);
    });

    it('sets the error message to the received one', () => {
      expect(state.errorMessage).toEqual(['network error']);
    });
  });

  describe(types.DISMISS_ERROR_ALERT, () => {
    beforeEach(() => {
      mutations[types.DISMISS_ERROR_ALERT](state);
    });

    it('sets the state to error dismissed', () => {
      expect(state.status).toBe(statuses.UNSYNCED);
    });
  });
});
