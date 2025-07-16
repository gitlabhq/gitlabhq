import { shallowMount } from '@vue/test-utils';
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import AdminProjectsApp from '~/admin/projects/index/components/app.vue';
import { programmingLanguages } from 'jest/groups_projects/components/mock_data';
import {
  FILTERED_SEARCH_TOKEN_LANGUAGE,
  FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
  FILTERED_SEARCH_TOKEN_VISIBILITY_LEVEL,
  FILTERED_SEARCH_TOKEN_NAMESPACE,
  PAGINATION_TYPE_KEYSET,
} from '~/groups_projects/constants';
import {
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
} from '~/projects/filtered_search_and_sort/constants';
import { RECENT_SEARCHES_STORAGE_KEY_PROJECTS } from '~/filtered_search/recent_searches_storage_keys';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
} from '~/vue_shared/components/resource_lists/constants';
import projectCountsQuery from '~/admin/projects/index/graphql/queries/project_counts.query.graphql';
import {
  ADMIN_PROJECTS_TABS,
  SORT_OPTIONS,
  SORT_OPTION_UPDATED,
  SORT_OPTION_CREATED,
  FIRST_TAB_ROUTE_NAMES,
} from '~/admin/projects/index/constants';

describe('AdminProjectsApp', () => {
  let wrapper;

  const defaultPropsData = {
    programmingLanguages,
  };

  const findTabsWithList = () => wrapper.findComponent(TabsWithList);

  const createComponent = () => {
    wrapper = shallowMount(AdminProjectsApp, { propsData: defaultPropsData });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders TabsWithList component and passes correct props', () => {
    expect(findTabsWithList().props()).toMatchObject({
      tabs: ADMIN_PROJECTS_TABS,
      filteredSearchSupportedTokens: [
        FILTERED_SEARCH_TOKEN_LANGUAGE,
        FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
        FILTERED_SEARCH_TOKEN_VISIBILITY_LEVEL,
        FILTERED_SEARCH_TOKEN_NAMESPACE,
      ],
      filteredSearchTermKey: FILTERED_SEARCH_TERM_KEY,
      filteredSearchNamespace: FILTERED_SEARCH_NAMESPACE,
      filteredSearchRecentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_PROJECTS,
      sortOptions: SORT_OPTIONS,
      defaultSortOption: SORT_OPTION_UPDATED,
      timestampTypeMap: {
        [SORT_OPTION_CREATED.value]: TIMESTAMP_TYPE_CREATED_AT,
        [SORT_OPTION_UPDATED.value]: TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
      },
      firstTabRouteNames: FIRST_TAB_ROUTE_NAMES,
      initialSort: '',
      programmingLanguages: defaultPropsData.programmingLanguages,
      tabCountsQuery: projectCountsQuery,
      tabCountsQueryErrorMessage: 'An error occurred loading the project counts.',
      paginationType: PAGINATION_TYPE_KEYSET,
    });
  });
});
