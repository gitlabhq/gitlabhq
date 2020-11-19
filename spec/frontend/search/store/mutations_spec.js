import mutations from '~/search/store/mutations';
import createState from '~/search/store/state';
import * as types from '~/search/store/mutation_types';
import { MOCK_QUERY, MOCK_GROUPS } from '../mock_data';

describe('Global Search Store Mutations', () => {
  let state;

  beforeEach(() => {
    state = createState({ query: MOCK_QUERY });
  });

  describe('REQUEST_GROUPS', () => {
    it('sets fetchingGroups to true', () => {
      mutations[types.REQUEST_GROUPS](state);

      expect(state.fetchingGroups).toBe(true);
    });
  });

  describe('RECEIVE_GROUPS_SUCCESS', () => {
    it('sets fetchingGroups to false and sets groups', () => {
      mutations[types.RECEIVE_GROUPS_SUCCESS](state, MOCK_GROUPS);

      expect(state.fetchingGroups).toBe(false);
      expect(state.groups).toBe(MOCK_GROUPS);
    });
  });

  describe('RECEIVE_GROUPS_ERROR', () => {
    it('sets fetchingGroups to false and clears groups', () => {
      mutations[types.RECEIVE_GROUPS_ERROR](state);

      expect(state.fetchingGroups).toBe(false);
      expect(state.groups).toEqual([]);
    });
  });

  describe('SET_QUERY', () => {
    const payload = { key: 'key1', value: 'value1' };

    it('sets query key to value', () => {
      mutations[types.SET_QUERY](state, payload);

      expect(state.query[payload.key]).toBe(payload.value);
    });
  });
});
