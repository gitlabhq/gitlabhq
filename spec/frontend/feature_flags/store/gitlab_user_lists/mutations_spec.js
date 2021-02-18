import * as types from '~/feature_flags/store/gitlab_user_list/mutation_types';
import mutations from '~/feature_flags/store/gitlab_user_list/mutations';
import createState from '~/feature_flags/store/gitlab_user_list/state';
import statuses from '~/feature_flags/store/gitlab_user_list/status';
import { userList } from '../../mock_data';

describe('~/feature_flags/store/gitlab_user_list/mutations', () => {
  let state;

  beforeEach(() => {
    state = createState({ projectId: '8' });
  });

  describe(types.SET_FILTER, () => {
    it('sets the filter in the state', () => {
      mutations[types.SET_FILTER](state, 'test');
      expect(state.filter).toBe('test');
    });
  });

  describe(types.FETCH_USER_LISTS, () => {
    it('sets the status to loading', () => {
      mutations[types.FETCH_USER_LISTS](state);
      expect(state.status).toBe(statuses.LOADING);
    });
  });

  describe(types.RECEIVE_USER_LISTS_SUCCESS, () => {
    it('sets the user lists to the ones received', () => {
      mutations[types.RECEIVE_USER_LISTS_SUCCESS](state, [userList]);
      expect(state.userLists).toEqual([userList]);
    });

    it('sets the status to idle', () => {
      mutations[types.RECEIVE_USER_LISTS_SUCCESS](state, [userList]);
      expect(state.status).toBe(statuses.IDLE);
    });
  });
  describe(types.RECEIVE_USER_LISTS_ERROR, () => {
    it('sets the status to error', () => {
      mutations[types.RECEIVE_USER_LISTS_ERROR](state, 'failure');
      expect(state.status).toBe(statuses.ERROR);
    });

    it('sets the error message', () => {
      mutations[types.RECEIVE_USER_LISTS_ERROR](state, 'failure');
      expect(state.error).toBe('failure');
    });
  });
});
