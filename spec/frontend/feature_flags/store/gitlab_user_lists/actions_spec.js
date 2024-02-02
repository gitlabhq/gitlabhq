import testAction from 'helpers/vuex_action_helper';
import Api from '~/api';
import { fetchUserLists, setFilter } from '~/feature_flags/store/gitlab_user_list/actions';
import * as types from '~/feature_flags/store/gitlab_user_list/mutation_types';
import createState from '~/feature_flags/store/gitlab_user_list/state';
import { userList } from '../../mock_data';

jest.mock('~/api');

describe('~/feature_flags/store/gitlab_user_list/actions', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = createState({ projectId: '1' });
    mockedState.filter = 'test';
  });

  describe('fetchUserLists', () => {
    it('should commit FETCH_USER_LISTS and RECEIEVE_USER_LISTS_SUCCESS on success', async () => {
      Api.searchFeatureFlagUserLists.mockResolvedValue({ data: [userList] });
      await testAction(
        fetchUserLists,
        undefined,
        mockedState,
        [
          { type: types.FETCH_USER_LISTS },
          { type: types.RECEIVE_USER_LISTS_SUCCESS, payload: [userList] },
        ],
        [],
      );
      expect(Api.searchFeatureFlagUserLists).toHaveBeenCalledWith('1', 'test');
    });

    it('should commit FETCH_USER_LISTS and RECEIEVE_USER_LISTS_ERROR on success', async () => {
      Api.searchFeatureFlagUserLists.mockRejectedValue({ message: 'error' });
      await testAction(
        fetchUserLists,
        undefined,
        mockedState,
        [
          { type: types.FETCH_USER_LISTS },
          { type: types.RECEIVE_USER_LISTS_ERROR, payload: ['error'] },
        ],
        [],
      );
      expect(Api.searchFeatureFlagUserLists).toHaveBeenCalledWith('1', 'test');
    });
  });

  describe('setFilter', () => {
    it('commits SET_FILTER and fetches new user lists', () =>
      testAction(
        setFilter,
        'filter',
        mockedState,
        [{ type: types.SET_FILTER, payload: 'filter' }],
        [{ type: 'fetchUserLists' }],
      ));
  });
});
