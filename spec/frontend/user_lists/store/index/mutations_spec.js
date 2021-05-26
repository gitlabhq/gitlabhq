import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import * as types from '~/user_lists/store/index/mutation_types';
import mutations from '~/user_lists/store/index/mutations';
import createState from '~/user_lists/store/index/state';
import { userList } from '../../../feature_flags/mock_data';

describe('~/user_lists/store/index/mutations', () => {
  let state;

  beforeEach(() => {
    state = createState({ projectId: '1' });
  });

  describe('SET_USER_LISTS_OPTIONS', () => {
    it('should set provided options', () => {
      mutations[types.SET_USER_LISTS_OPTIONS](state, { page: '1', scope: 'all' });

      expect(state.options).toEqual({ page: '1', scope: 'all' });
    });
  });

  describe('REQUEST_USER_LISTS', () => {
    it('sets isLoading to true', () => {
      mutations[types.REQUEST_USER_LISTS](state);
      expect(state.isLoading).toBe(true);
    });
  });

  describe('RECEIVE_USER_LISTS_SUCCESS', () => {
    const headers = {
      'x-next-page': '2',
      'x-page': '1',
      'X-Per-Page': '2',
      'X-Prev-Page': '',
      'X-TOTAL': '37',
      'X-Total-Pages': '5',
    };

    beforeEach(() => {
      mutations[types.RECEIVE_USER_LISTS_SUCCESS](state, { data: [userList], headers });
    });

    it('sets isLoading to false', () => {
      expect(state.isLoading).toBe(false);
    });

    it('sets userLists to the received userLists', () => {
      expect(state.userLists).toEqual([userList]);
    });

    it('sets pagination info for user lits', () => {
      expect(state.pageInfo).toEqual(parseIntPagination(normalizeHeaders(headers)));
    });

    it('sets the count for user lists', () => {
      expect(state.count).toBe(parseInt(headers['X-TOTAL'], 10));
    });
  });

  describe('RECEIVE_USER_LISTS_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_USER_LISTS_ERROR](state);
    });

    it('should set isLoading to false', () => {
      expect(state.isLoading).toEqual(false);
    });

    it('should set hasError to true', () => {
      expect(state.hasError).toEqual(true);
    });
  });

  describe('REQUEST_DELETE_USER_LIST', () => {
    beforeEach(() => {
      state.userLists = [userList];
      mutations[types.REQUEST_DELETE_USER_LIST](state, userList);
    });

    it('should remove the deleted list', () => {
      expect(state.userLists).not.toContain(userList);
    });
  });

  describe('RECEIVE_DELETE_USER_LIST_ERROR', () => {
    beforeEach(() => {
      state.userLists = [];
      mutations[types.RECEIVE_DELETE_USER_LIST_ERROR](state, {
        list: userList,
        error: 'some error',
      });
    });

    it('should set isLoading to false and hasError to false', () => {
      expect(state.isLoading).toBe(false);
      expect(state.hasError).toBe(false);
    });

    it('should add the user list back to the list of user lists', () => {
      expect(state.userLists).toContain(userList);
    });
  });

  describe('RECEIVE_CLEAR_ALERT', () => {
    it('clears the alert', () => {
      state.alerts = ['a server error'];

      mutations[types.RECEIVE_CLEAR_ALERT](state, 0);

      expect(state.alerts).toEqual([]);
    });

    it('clears the alert at the specified index', () => {
      state.alerts = ['a server error', 'another error', 'final error'];

      mutations[types.RECEIVE_CLEAR_ALERT](state, 1);

      expect(state.alerts).toEqual(['a server error', 'final error']);
    });
  });
});
