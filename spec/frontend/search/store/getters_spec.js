import { GROUPS_LOCAL_STORAGE_KEY, PROJECTS_LOCAL_STORAGE_KEY } from '~/search/store/constants';
import * as getters from '~/search/store/getters';
import createState from '~/search/store/state';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import {
  MOCK_QUERY,
  MOCK_GROUPS,
  MOCK_PROJECTS,
  MOCK_AGGREGATIONS,
  MOCK_LANGUAGE_AGGREGATIONS_BUCKETS,
  TEST_FILTER_DATA,
} from '../mock_data';

describe('Global Search Store Getters', () => {
  let state;

  beforeEach(() => {
    state = createState({ query: MOCK_QUERY });
    useMockLocationHelper();
  });

  describe('frequentGroups', () => {
    it('returns the correct data', () => {
      state.frequentItems[GROUPS_LOCAL_STORAGE_KEY] = MOCK_GROUPS;
      expect(getters.frequentGroups(state)).toStrictEqual(MOCK_GROUPS);
    });
  });

  describe('frequentProjects', () => {
    it('returns the correct data', () => {
      state.frequentItems[PROJECTS_LOCAL_STORAGE_KEY] = MOCK_PROJECTS;
      expect(getters.frequentProjects(state)).toStrictEqual(MOCK_PROJECTS);
    });
  });

  describe('langugageAggregationBuckets', () => {
    it('returns the correct data', () => {
      state.aggregations.data = MOCK_AGGREGATIONS;
      expect(getters.langugageAggregationBuckets(state)).toStrictEqual(
        MOCK_LANGUAGE_AGGREGATIONS_BUCKETS,
      );
    });
  });

  describe('queryLangugageFilters', () => {
    it('returns the correct data', () => {
      state.query.language = Object.keys(TEST_FILTER_DATA.filters);
      expect(getters.queryLangugageFilters(state)).toStrictEqual(state.query.language);
    });
  });

  describe('currentUrlQueryHasLanguageFilters', () => {
    it.each`
      description             | lang                        | result
      ${'has valid language'} | ${{ language: ['a', 'b'] }} | ${true}
      ${'has empty lang'}     | ${{ language: [] }}         | ${false}
      ${'has no lang'}        | ${{}}                       | ${false}
    `('$description', ({ lang, result }) => {
      state.urlQuery = lang;
      expect(getters.currentUrlQueryHasLanguageFilters(state)).toBe(result);
    });
  });
});
