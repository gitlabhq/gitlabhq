import mutations from '~/search/store/mutations';
import createState from '~/search/store/state';
import * as types from '~/search/store/mutation_types';
import {
  MOCK_QUERY,
  MOCK_GROUPS,
  MOCK_PROJECTS,
  MOCK_SEARCH_COUNTS,
  MOCK_SCOPE_TABS,
} from '../mock_data';

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
      expect(state.projects).toBe(MOCK_PROJECTS);
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

  describe('REQUEST_SEARCH_COUNTS', () => {
    it('sets the count to for the query.scope activeCount', () => {
      const payload = { scopeTabs: ['issues'], activeCount: '22' };
      mutations[types.REQUEST_SEARCH_COUNTS](state, payload);

      expect(state.inflatedScopeTabs).toStrictEqual([
        { scope: 'issues', title: 'Issues', count: '22' },
      ]);
    });

    it('sets other scopes count to empty string', () => {
      const payload = { scopeTabs: ['milestones'], activeCount: '22' };
      mutations[types.REQUEST_SEARCH_COUNTS](state, payload);

      expect(state.inflatedScopeTabs).toStrictEqual([
        { scope: 'milestones', title: 'Milestones', count: '' },
      ]);
    });
  });

  describe('RECEIVE_SEARCH_COUNTS_SUCCESS', () => {
    it('sets the count from the input for all tabs', () => {
      mutations[types.RECEIVE_SEARCH_COUNTS_SUCCESS](state, MOCK_SEARCH_COUNTS);

      expect(state.inflatedScopeTabs).toStrictEqual(MOCK_SCOPE_TABS);
    });
  });
});
