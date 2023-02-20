import { GROUPS_LOCAL_STORAGE_KEY, PROJECTS_LOCAL_STORAGE_KEY } from '~/search/store/constants';
import * as getters from '~/search/store/getters';
import createState from '~/search/store/state';
import {
  MOCK_QUERY,
  MOCK_GROUPS,
  MOCK_PROJECTS,
  MOCK_AGGREGATIONS,
  MOCK_LANGUAGE_AGGREGATIONS_BUCKETS,
} from '../mock_data';

describe('Global Search Store Getters', () => {
  let state;

  beforeEach(() => {
    state = createState({ query: MOCK_QUERY });
  });

  describe('frequentGroups', () => {
    beforeEach(() => {
      state.frequentItems[GROUPS_LOCAL_STORAGE_KEY] = MOCK_GROUPS;
    });

    it('returns the correct data', () => {
      expect(getters.frequentGroups(state)).toStrictEqual(MOCK_GROUPS);
    });
  });

  describe('frequentProjects', () => {
    beforeEach(() => {
      state.frequentItems[PROJECTS_LOCAL_STORAGE_KEY] = MOCK_PROJECTS;
    });

    it('returns the correct data', () => {
      expect(getters.frequentProjects(state)).toStrictEqual(MOCK_PROJECTS);
    });
  });

  describe('langugageAggregationBuckets', () => {
    beforeEach(() => {
      state.aggregations.data = MOCK_AGGREGATIONS;
    });

    it('returns the correct data', () => {
      expect(getters.langugageAggregationBuckets(state)).toStrictEqual(
        MOCK_LANGUAGE_AGGREGATIONS_BUCKETS,
      );
    });
  });
});
