import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AdminGroupsApp from '~/admin/groups/index/components/app.vue';
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import { PAGINATION_TYPE_KEYSET } from '~/groups_projects/constants';
import { RECENT_SEARCHES_STORAGE_KEY_GROUPS } from '~/filtered_search/recent_searches_storage_keys';
import {
  SORT_OPTIONS,
  SORT_OPTION_UPDATED,
  SORT_OPTION_CREATED,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
  ADMIN_GROUPS_TABS,
  FIRST_TAB_ROUTE_NAMES,
} from '~/admin/groups/index/constants';
import adminGroupCountsQuery from '~/admin/groups/index/graphql/queries/group_counts.query.graphql';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';

describe('AdminGroupsApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(AdminGroupsApp);
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders TabsWithList component and passes correct props', () => {
    expect(wrapper.findComponent(TabsWithList).props()).toMatchObject({
      tabs: ADMIN_GROUPS_TABS,
      filteredSearchTermKey: FILTERED_SEARCH_TERM_KEY,
      filteredSearchNamespace: FILTERED_SEARCH_NAMESPACE,
      filteredSearchRecentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_GROUPS,
      filteredSearchInputPlaceholder: 'Search (3 character minimum)',
      sortOptions: SORT_OPTIONS,
      defaultSortOption: SORT_OPTION_UPDATED,
      timestampTypeMap: {
        [SORT_OPTION_CREATED.value]: TIMESTAMP_TYPE_CREATED_AT,
        [SORT_OPTION_UPDATED.value]: TIMESTAMP_TYPE_UPDATED_AT,
      },
      initialSort: '',
      shouldUpdateActiveTabCountFromTabQuery: true,
      paginationType: PAGINATION_TYPE_KEYSET,
      tabCountsQuery: adminGroupCountsQuery,
      tabCountsQueryErrorMessage: 'An error occurred loading the group counts.',
      firstTabRouteNames: FIRST_TAB_ROUTE_NAMES,
    });
  });
});
