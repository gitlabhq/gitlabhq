import { shallowMount } from '@vue/test-utils';
import YourWorkGroupsApp from '~/groups/your_work/components/app.vue';
import groupCountsQuery from '~/groups/your_work/graphql/queries/group_counts.query.graphql';
import {
  GROUP_DASHBOARD_TABS,
  SORT_OPTIONS,
  SORT_OPTION_UPDATED,
  SORT_OPTION_CREATED,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
} from '~/groups/your_work/constants';
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import { RECENT_SEARCHES_STORAGE_KEY_GROUPS } from '~/filtered_search/recent_searches_storage_keys';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import { PAGINATION_TYPE_OFFSET } from '~/groups_projects/constants';

describe('YourWorkGroupsApp', () => {
  let wrapper;

  const defaultPropsData = {
    initialSort: 'created_desc',
  };

  const createComponent = () => {
    wrapper = shallowMount(YourWorkGroupsApp, { propsData: defaultPropsData });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders TabsWithList component and passes correct props', () => {
    expect(wrapper.findComponent(TabsWithList).props()).toEqual({
      tabs: GROUP_DASHBOARD_TABS,
      filteredSearchSupportedTokens: [],
      filteredSearchTermKey: FILTERED_SEARCH_TERM_KEY,
      filteredSearchNamespace: FILTERED_SEARCH_NAMESPACE,
      filteredSearchRecentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_GROUPS,
      filteredSearchInputPlaceholder: 'Search',
      sortOptions: SORT_OPTIONS,
      defaultSortOption: SORT_OPTION_UPDATED,
      timestampTypeMap: {
        [SORT_OPTION_CREATED.value]: TIMESTAMP_TYPE_CREATED_AT,
        [SORT_OPTION_UPDATED.value]: TIMESTAMP_TYPE_UPDATED_AT,
      },
      firstTabRouteNames: [],
      initialSort: defaultPropsData.initialSort,
      programmingLanguages: [],
      eventTracking: {},
      tabCountsQuery: groupCountsQuery,
      tabCountsQueryErrorMessage: 'An error occurred loading the group counts.',
      shouldUpdateActiveTabCountFromTabQuery: false,
      paginationType: PAGINATION_TYPE_OFFSET,
    });
  });
});
