import * as types from '~/search/store/mutation_types';
import mutations from '~/search/store/mutations';
import createState from '~/search/store/state';
import {
  MOCK_QUERY,
  MOCK_GROUPS,
  MOCK_PROJECTS,
  MOCK_NAVIGATION_DATA,
  MOCK_NAVIGATION_ACTION_MUTATION,
  MOCK_DATA_FOR_NAVIGATION_ACTION_MUTATION,
  MOCK_AGGREGATIONS,
} from '../mock_data';

describe('Global Search Store Mutations', () => {
  let state;

  beforeEach(() => {
    state = createState({ query: MOCK_QUERY, navigation: MOCK_NAVIGATION_DATA });
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
      expect(state.groups).toStrictEqual(MOCK_GROUPS);
    });
  });

  describe('RECEIVE_GROUPS_ERROR', () => {
    it('sets fetchingGroups to false and clears groups', () => {
      mutations[types.RECEIVE_GROUPS_ERROR](state);

      expect(state.fetchingGroups).toBe(false);
      expect(state.groups).toEqual([]);
    });
  });

  describe('REQUEST_PROJECTS', () => {
    it('sets fetchingProjects to true', () => {
      mutations[types.REQUEST_PROJECTS](state);

      expect(state.fetchingProjects).toBe(true);
    });
  });

  describe('RECEIVE_PROJECTS_SUCCESS', () => {
    it('sets fetchingProjects to false and sets projects', () => {
      mutations[types.RECEIVE_PROJECTS_SUCCESS](state, MOCK_PROJECTS);

      expect(state.fetchingProjects).toBe(false);
      expect(state.projects).toStrictEqual(MOCK_PROJECTS);
    });
  });

  describe('RECEIVE_PROJECTS_ERROR', () => {
    it('sets fetchingProjects to false and clears projects', () => {
      mutations[types.RECEIVE_PROJECTS_ERROR](state);

      expect(state.fetchingProjects).toBe(false);
      expect(state.projects).toEqual([]);
    });
  });

  describe('SET_QUERY', () => {
    const payload = { key: 'key1', value: 'value1' };

    it('sets query key to value', () => {
      mutations[types.SET_QUERY](state, payload);

      expect(state.query[payload.key]).toBe(payload.value);
    });
  });

  describe('SET_SIDEBAR_DIRTY', () => {
    const value = true;

    it('sets sidebarDirty to the value', () => {
      mutations[types.SET_SIDEBAR_DIRTY](state, value);

      expect(state.sidebarDirty).toBe(value);
    });
  });

  describe('LOAD_FREQUENT_ITEMS', () => {
    it('sets frequentItems[key] to data', () => {
      const payload = { key: 'test-key', data: [1, 2, 3] };
      mutations[types.LOAD_FREQUENT_ITEMS](state, payload);

      expect(state.frequentItems[payload.key]).toStrictEqual(payload.data);
    });
  });

  describe('RECEIVE_NAVIGATION_COUNT', () => {
    it('sets frequentItems[key] to data', () => {
      const { payload } = MOCK_NAVIGATION_ACTION_MUTATION;
      mutations[types.RECEIVE_NAVIGATION_COUNT](state, payload);

      expect(state.navigation[payload.key]).toStrictEqual(
        MOCK_DATA_FOR_NAVIGATION_ACTION_MUTATION[payload.key],
      );
    });
  });

  describe.each`
    mutation                              | data                 | result
    ${types.REQUEST_AGGREGATIONS}         | ${[]}                | ${{ fetching: true, error: false, data: [] }}
    ${types.RECEIVE_AGGREGATIONS_SUCCESS} | ${MOCK_AGGREGATIONS} | ${{ fetching: false, error: false, data: MOCK_AGGREGATIONS }}
    ${types.RECEIVE_AGGREGATIONS_ERROR}   | ${[]}                | ${{ fetching: false, error: true, data: [] }}
  `('$mutation', ({ mutation, data, result }) => {
    it('sets correct object content', () => {
      mutations[mutation](state, data);

      expect(state.aggregations).toStrictEqual(result);
    });
  });

  describe('SET_LABEL_SEARCH_STRING', () => {
    it('sets the search string to the given data', () => {
      mutations[types.SET_LABEL_SEARCH_STRING](state, 'test');

      expect(state.searchLabelString).toBe('test');
    });
  });
});
