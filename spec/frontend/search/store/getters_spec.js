import { cloneDeep } from 'lodash-es';
import {
  GROUPS_LOCAL_STORAGE_KEY,
  PROJECTS_LOCAL_STORAGE_KEY,
  LS_REGEX_HANDLE,
  SIDEBAR_PARAMS,
} from '~/search/store/constants';
import { SCOPE_BLOB, SCOPE_PROJECTS } from '~/search/sidebar/constants';

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
  MOCK_NAVIGATION,
  MOCK_NAVIGATION_ITEMS,
  MOCK_LABEL_AGGREGATIONS,
  SMALL_MOCK_AGGREGATIONS,
  MOCK_LABEL_SEARCH_RESULT,
  MOCK_FILTERED_APPLIED_SELECTED_LABELS,
  MOCK_FILTERED_UNSELECTED_LABELS,
  MOCK_WORK_ITEM_TYPE_AGGREGATION_BUCKETS,
  MOCK_WORK_ITEM_TYPE_AGGREGATIONS,
} from '../mock_data';

describe('Global Search Store Getters', () => {
  let state;
  const defaultState = createState({ query: MOCK_QUERY });

  defaultState.aggregations = MOCK_LABEL_AGGREGATIONS;
  defaultState.aggregations.data.push(SMALL_MOCK_AGGREGATIONS[0]);

  useMockLocationHelper();

  beforeEach(() => {
    state = cloneDeep(defaultState);
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

  describe('languageAggregationBuckets', () => {
    it('returns the correct data', () => {
      state.aggregations.data = MOCK_AGGREGATIONS;
      expect(getters.languageAggregationBuckets(state)).toStrictEqual(
        MOCK_LANGUAGE_AGGREGATIONS_BUCKETS,
      );
    });
  });

  describe('queryLanguageFilters', () => {
    it('returns the correct data', () => {
      state.query.language = Object.keys(TEST_FILTER_DATA.filters);
      expect(getters.queryLanguageFilters(state)).toStrictEqual(state.query.language);
    });

    it('wraps a single value in an array', () => {
      state.query.language = 'Ruby';
      expect(getters.queryLanguageFilters(state)).toStrictEqual(['Ruby']);
    });

    it('returns an empty array when unset', () => {
      state.query.language = undefined;
      expect(getters.queryLanguageFilters(state)).toStrictEqual([]);
    });
  });

  describe('currentScope', () => {
    it('returns the correct scope name', () => {
      state.navigation = MOCK_NAVIGATION;
      expect(getters.currentScope(state)).toBe('issues');
    });
  });

  describe('navigationItems', () => {
    it('returns the re-mapped navigation data', () => {
      localStorage.setItem(LS_REGEX_HANDLE, JSON.stringify(true));

      state.navigation = MOCK_NAVIGATION;
      expect(getters.navigationItems(state)).toStrictEqual(MOCK_NAVIGATION_ITEMS);
    });

    it('returns "-" when count is unavailable', () => {
      state.navigation = {
        projects: {
          label: 'Projects',
          scope: 'projects',
          link: '/search?scope=projects&search=et',
          count: undefined,
        },
      };

      const result = getters.navigationItems(state);

      expect(result[0].pill_count).toBe('-');
    });
  });

  describe('labelAggregationBuckets', () => {
    it('strips labels buckets from all aggregations', () => {
      expect(getters.labelAggregationBuckets(state)).toStrictEqual(
        MOCK_LABEL_AGGREGATIONS.data[0].buckets,
      );
    });
  });

  describe('workItemTypeAggregationBuckets', () => {
    it('returns work item type buckets from aggregations', () => {
      state.aggregations = MOCK_WORK_ITEM_TYPE_AGGREGATIONS;
      expect(getters.workItemTypeAggregationBuckets(state)).toStrictEqual(
        MOCK_WORK_ITEM_TYPE_AGGREGATION_BUCKETS,
      );
    });

    it('returns empty array when no work item type aggregation exists', () => {
      state.aggregations = MOCK_LABEL_AGGREGATIONS;
      expect(getters.workItemTypeAggregationBuckets(state)).toStrictEqual([]);
    });
  });

  describe('filteredLabels', () => {
    it('gets all labels if no string is set', () => {
      state.searchLabelString = '';
      expect(getters.filteredLabels(state)).toStrictEqual(MOCK_LABEL_AGGREGATIONS.data[0].buckets);
    });

    it('get correct labels if string is set', () => {
      state.searchLabelString = 'SYNC';
      expect(getters.filteredLabels(state)).toStrictEqual([MOCK_LABEL_SEARCH_RESULT]);
    });
  });

  describe('filteredAppliedSelectedLabels', () => {
    it('returns all labels that are selected (part of URL)', () => {
      expect(getters.filteredAppliedSelectedLabels(state)).toStrictEqual(
        MOCK_FILTERED_APPLIED_SELECTED_LABELS,
      );
    });

    it('returns labels that are selected (part of URL) and result of search', () => {
      state.searchLabelString = 'SYNC';
      expect(getters.filteredAppliedSelectedLabels(state)).toStrictEqual([
        MOCK_FILTERED_APPLIED_SELECTED_LABELS[1],
      ]);
    });
  });

  describe('appliedSelectedLabels', () => {
    it('returns all labels that are selected (part of URL) no search', () => {
      state.searchLabelString = 'SYNC';
      expect(getters.appliedSelectedLabels(state)).toStrictEqual(
        MOCK_FILTERED_APPLIED_SELECTED_LABELS,
      );
    });
  });

  describe('filteredUnselectedLabels', () => {
    it('returns all labels that are selected (part of URL) no search', () => {
      expect(getters.filteredUnselectedLabels(state)).toStrictEqual(
        MOCK_FILTERED_UNSELECTED_LABELS,
      );
    });

    it('returns labels that are selected (part of URL) and result of search', () => {
      state.searchLabelString = 'ACC';
      expect(getters.filteredUnselectedLabels(state)).toStrictEqual([
        MOCK_FILTERED_UNSELECTED_LABELS[1],
      ]);
    });
  });

  describe('unselectedLabels', () => {
    it('returns all labels that are not selected', () => {
      state.query.label_name = ['Brist'];
      expect(getters.unselectedLabels(state)).toStrictEqual([MOCK_LABEL_SEARCH_RESULT]);
    });
  });

  describe('unappliedNewLabels', () => {
    it('returns all labels that are selected but not applied', () => {
      // Applied labels
      state.urlQuery.label_name = ['Aftersync', 'Brist'];
      // Applied and selected labels
      state.query.label_name = ['Aftersync', 'Cosche', 'Accent', 'Brist'];
      // Selected but unapplied labels
      // expect(getters.unappliedNewLabels(state)).toStrictEqual(MOCK_FILTERED_UNSELECTED_LABELS);
      expect(getters.unappliedNewLabels(state).map(({ key }) => key)).toStrictEqual(['6', '73']);
    });
  });
  describe('hasMissingProjectContext', () => {
    it('returns true projectInitialJson.id is NOT in query', () => {
      state.projectInitialJson = {
        id: undefined,
      };
      expect(getters.hasMissingProjectContext(state)).toBe(true);
    });

    it('returns false projectInitialJson.id is in query', () => {
      state.projectInitialJson = {
        id: 'test',
      };
      expect(getters.hasMissingProjectContext(state)).toBe(false);
    });
  });

  describe('isZoektCodeSearch', () => {
    it.each`
      searchType    | currentScope | expected
      ${'zoekt'}    | ${'blobs'}   | ${true}
      ${'zoekt'}    | ${'issues'}  | ${false}
      ${'advanced'} | ${'blobs'}   | ${false}
      ${'basic'}    | ${'blobs'}   | ${false}
    `(
      'returns $expected with $searchType search in the $currentScope scope',
      ({ searchType, currentScope, expected }) => {
        state.searchType = searchType;

        expect(getters.isZoektCodeSearch(state, { currentScope })).toBe(expected);
      },
    );
  });

  describe('hasAppliedFilters', () => {
    const appliedFilters = [
      ['type', ['issue']],
      ['state', 'opened'],
      ['confidential', 'yes'],
      ['language', ['Ruby']],
      ['label_name', ['bug']],
      ['include_archived', 'true'],
      ['exclude_forks', 'true'],
      ['source_branch', 'main'],
      ['not[source_branch]', 'main'],
      ['target_branch', 'main'],
      ['not[target_branch]', 'main'],
      ['author_username', 'root'],
      ['not[author_username]', 'root'],
    ];
    const clearedFilters = [
      ['type', []],
      ['state', null],
      ['confidential', null],
      ['language', []],
      ['label_name', []],
      ['include_archived', 'false'],
      ['exclude_forks', 'false'],
      ['source_branch', ''],
      ['not[source_branch]', ''],
      ['target_branch', ''],
      ['not[target_branch]', ''],
      ['author_username', ''],
      ['not[author_username]', ''],
    ];
    const unfilteredQuery = { scope: 'issues', search: 'test', group_id: 1 };
    const issuesScopeGetters = {
      currentScope: 'issues',
      isZoektCodeSearch: false,
      sidebarFilterParams: SIDEBAR_PARAMS,
    };
    const withSidebarFilterParams = (scopeGetters) => ({
      ...scopeGetters,
      sidebarFilterParams: getters.sidebarFilterParams(state, scopeGetters),
    });

    it('checks every sidebar filter param', () => {
      expect(appliedFilters.map(([param]) => param)).toEqual(SIDEBAR_PARAMS);
    });

    it('returns false when the applied query has no sidebar filters', () => {
      state.query = unfilteredQuery;
      state.urlQuery = unfilteredQuery;

      expect(getters.hasAppliedFilters(state, issuesScopeGetters)).toBe(false);
    });

    describe.each(appliedFilters)('with the %s filter', (param, value) => {
      it('returns true when the filter is applied', () => {
        state.query = { ...unfilteredQuery, [param]: value };
        state.urlQuery = { ...unfilteredQuery, [param]: value };

        expect(getters.hasAppliedFilters(state, issuesScopeGetters)).toBe(true);
      });

      it('returns false when the filter is selected but not applied', () => {
        state.query = { ...unfilteredQuery, [param]: value };
        state.urlQuery = unfilteredQuery;

        expect(getters.hasAppliedFilters(state, issuesScopeGetters)).toBe(false);
      });

      it('returns true when the applied filter is cleared but not applied', () => {
        state.query = unfilteredQuery;
        state.urlQuery = { ...unfilteredQuery, [param]: value };

        expect(getters.hasAppliedFilters(state, issuesScopeGetters)).toBe(true);
      });
    });

    it.each(clearedFilters)('returns false when %s is applied as %p', (param, value) => {
      state.query = { ...unfilteredQuery, [param]: value };
      state.urlQuery = { ...unfilteredQuery, [param]: value };

      expect(getters.hasAppliedFilters(state, issuesScopeGetters)).toBe(false);
    });

    describe('with a filter the current scope does not show', () => {
      const projectsScopeGetters = {
        currentScope: 'projects',
        isZoektCodeSearch: false,
        hasMissingProjectContext: true,
        workItemTypes: [],
      };

      it('returns false when only that filter is applied', () => {
        state.query = { ...unfilteredQuery, scope: 'projects', state: 'opened' };
        state.urlQuery = { ...unfilteredQuery, scope: 'projects', state: 'opened' };

        expect(
          getters.hasAppliedFilters(state, withSidebarFilterParams(projectsScopeGetters)),
        ).toBe(false);
      });

      it('returns true when a filter the scope shows is applied as well', () => {
        const query = { ...unfilteredQuery, scope: 'projects', state: 'opened' };
        state.query = { ...query, include_archived: 'true' };
        state.urlQuery = { ...query, include_archived: 'true' };

        expect(
          getters.hasAppliedFilters(state, withSidebarFilterParams(projectsScopeGetters)),
        ).toBe(true);
      });
    });

    describe('with Zoekt code search, which applies filters as they change', () => {
      const blobsScopeGetters = {
        currentScope: 'blobs',
        isZoektCodeSearch: true,
        hasMissingProjectContext: true,
        workItemTypes: [],
      };

      beforeEach(() => {
        state.searchType = 'zoekt';
      });

      it.each([
        ['language', ['Ruby']],
        ['include_archived', 'true'],
        ['exclude_forks', 'true'],
      ])('returns true as soon as %s is selected', (param, value) => {
        state.query = { ...unfilteredQuery, scope: 'blobs', [param]: value };
        state.urlQuery = { ...unfilteredQuery, scope: 'blobs' };

        expect(getters.hasAppliedFilters(state, withSidebarFilterParams(blobsScopeGetters))).toBe(
          true,
        );
      });

      it('returns false when only a filter the scope does not show is selected', () => {
        state.query = { ...unfilteredQuery, scope: 'blobs', state: 'opened' };
        state.urlQuery = { ...unfilteredQuery, scope: 'blobs' };

        expect(getters.hasAppliedFilters(state, withSidebarFilterParams(blobsScopeGetters))).toBe(
          false,
        );
      });

      it('returns false as soon as the filters are cleared', () => {
        state.query = { ...unfilteredQuery, scope: 'blobs', language: [] };
        state.urlQuery = { ...unfilteredQuery, scope: 'blobs', language: ['Ruby'] };

        expect(getters.hasAppliedFilters(state, withSidebarFilterParams(blobsScopeGetters))).toBe(
          false,
        );
      });

      it('reads the applied filters from the URL in other scopes', () => {
        state.query = { ...unfilteredQuery, state: 'opened' };
        state.urlQuery = unfilteredQuery;

        expect(getters.hasAppliedFilters(state, issuesScopeGetters)).toBe(false);
      });
    });
  });

  describe('sidebarFilterParams', () => {
    const contexts = {
      instance: { groupInitialJson: {}, hasMissingProjectContext: true },
      group: { groupInitialJson: { id: 1 }, hasMissingProjectContext: true },
      project: { groupInitialJson: { id: 1 }, hasMissingProjectContext: false },
    };
    const branchParams = [
      'source_branch',
      'not[source_branch]',
      'target_branch',
      'not[target_branch]',
    ];
    const advancedParams = ['author_username', 'not[author_username]', 'label_name'];

    const getSidebarFilterParams = ({ scope, searchType, context, workItemTypes = [] }) => {
      const { groupInitialJson, hasMissingProjectContext } = contexts[context];

      return getters.sidebarFilterParams(
        { searchType, groupInitialJson },
        { currentScope: scope, hasMissingProjectContext, workItemTypes },
      );
    };

    it.each`
      scope               | searchType    | context       | expected
      ${'projects'}       | ${'basic'}    | ${'instance'} | ${['include_archived']}
      ${'groups'}         | ${'advanced'} | ${'instance'} | ${['include_archived']}
      ${'issues'}         | ${'basic'}    | ${'project'}  | ${['state', 'confidential']}
      ${'issues'}         | ${'advanced'} | ${'group'}    | ${['state', 'confidential', ...advancedParams, 'include_archived']}
      ${'work_items'}     | ${'basic'}    | ${'project'}  | ${['state', 'confidential']}
      ${'merge_requests'} | ${'basic'}    | ${'instance'} | ${['state', 'include_archived']}
      ${'merge_requests'} | ${'basic'}    | ${'project'}  | ${['state', ...branchParams]}
      ${'merge_requests'} | ${'advanced'} | ${'group'}    | ${['state', 'include_archived', ...branchParams, ...advancedParams]}
      ${'blobs'}          | ${'basic'}    | ${'group'}    | ${[]}
      ${'blobs'}          | ${'advanced'} | ${'group'}    | ${['language', 'include_archived']}
      ${'blobs'}          | ${'zoekt'}    | ${'group'}    | ${['language', 'include_archived', 'exclude_forks']}
      ${'blobs'}          | ${'zoekt'}    | ${'project'}  | ${['language']}
      ${'notes'}          | ${'basic'}    | ${'group'}    | ${['include_archived']}
      ${'commits'}        | ${'basic'}    | ${'group'}    | ${['include_archived']}
      ${'milestones'}     | ${'basic'}    | ${'group'}    | ${['include_archived']}
      ${'wiki_blobs'}     | ${'basic'}    | ${'group'}    | ${['include_archived']}
      ${'wiki_blobs'}     | ${'basic'}    | ${'project'}  | ${[]}
      ${'users'}          | ${'basic'}    | ${'group'}    | ${[]}
    `(
      'returns $expected in the $scope scope with $searchType search in a $context',
      ({ scope, searchType, context, expected }) => {
        expect(getSidebarFilterParams({ scope, searchType, context })).toEqual(expected);
      },
    );

    it('places every sidebar filter param in at least one scope', () => {
      const searchTypes = ['basic', 'advanced', 'zoekt'];
      const scopes = ['issues', 'work_items', 'merge_requests', 'blobs', 'projects', 'notes'];
      const workItemTypes = [{ name: 'issue', label: 'Issue' }];
      const placedParams = new Set(
        scopes.flatMap((scope) =>
          searchTypes.flatMap((searchType) =>
            Object.keys(contexts).flatMap((context) =>
              getSidebarFilterParams({ scope, searchType, context, workItemTypes }),
            ),
          ),
        ),
      );

      expect([...placedParams].sort()).toEqual([...SIDEBAR_PARAMS].sort());
    });

    it('includes the type filter for work items when work item types are available', () => {
      expect(
        getSidebarFilterParams({
          scope: 'work_items',
          searchType: 'basic',
          context: 'project',
          workItemTypes: [{ name: 'issue', label: 'Issue' }],
        }),
      ).toEqual(['type', 'state', 'confidential']);
    });
  });

  describe('searchNavigationLink', () => {
    const { searchNavigationLink } = getters;

    it('adds default search term "*" when no search query exists', () => {
      state.query.search = '';
      const item = { link: '/search', scope: SCOPE_PROJECTS };

      const result = searchNavigationLink(item, state);

      expect(result).toBe('/search?search=*');
    });

    it('adds default search term "*" for blob scope when no search query exists', () => {
      state.query.search = '';
      localStorage.setItem(LS_REGEX_HANDLE, JSON.stringify(false));
      const item = { link: '/search', scope: SCOPE_BLOB };

      const result = searchNavigationLink(item, state);

      expect(result).toBe('/search?search=*');
    });

    it('does not add default search term when search query exists', () => {
      state.query.search = 'existing query';
      const item = { link: '/search', scope: SCOPE_PROJECTS };

      const result = searchNavigationLink(item, state);

      expect(result).toBe('/search?');
    });

    it('uses injectRegexSearch for blob scope even when search query exists', () => {
      state.query.search = 'existing query';
      localStorage.setItem(LS_REGEX_HANDLE, JSON.stringify(true));
      const item = { link: '/search', scope: SCOPE_BLOB };

      const result = searchNavigationLink(item, state);

      expect(result).toBe('/search?regex=true');
    });

    it('adds default search term "*" and uses injectRegexSearch', () => {
      state.query.search = '';
      localStorage.setItem(LS_REGEX_HANDLE, JSON.stringify(true));
      const item = { link: '/search', scope: SCOPE_BLOB };

      const result = searchNavigationLink(item, state);

      expect(result).toBe('/search?regex=true&search=*');
    });
  });
});
