import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import dashboardGroupsResponse from 'test_fixtures/groups/dashboard/index.json';
import YourWorkGroupsApp from '~/groups/your_work/components/app.vue';
import NestedGroupsProjectsList from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list.vue';
import NestedGroupsProjectsListItem from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list_item.vue';
import { createRouter } from '~/groups/your_work';
import groupCountsQuery from '~/groups/your_work/graphql/queries/group_counts.query.graphql';
import {
  GROUP_DASHBOARD_TABS,
  SORT_OPTIONS,
  SORT_OPTION_UPDATED,
  SORT_OPTION_CREATED,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
  GROUPS_DASHBOARD_ROUTE_NAME,
} from '~/groups/your_work/constants';
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import { RECENT_SEARCHES_STORAGE_KEY_GROUPS } from '~/filtered_search/recent_searches_storage_keys';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import { PAGINATION_TYPE_OFFSET } from '~/groups_projects/constants';
import axios from '~/lib/utils/axios_utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import { resolvers } from '~/groups/your_work/graphql/resolvers';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);
Vue.use(VueRouter);
// We need to globally render components to avoid circular references
// https://v2.vuejs.org/v2/guide/components-edge-cases.html#Circular-References-Between-Components
Vue.component('NestedGroupsProjectsList', NestedGroupsProjectsList);
Vue.component('NestedGroupsProjectsListItem', NestedGroupsProjectsListItem);

describe('YourWorkGroupsApp', () => {
  let wrapper;
  let mockAxios;
  let router;

  const defaultPropsData = {
    initialSort: 'created_desc',
  };

  const endpoint = '/dashboard/groups.json';
  const defaultRoute = {
    name: GROUPS_DASHBOARD_ROUTE_NAME,
  };

  const createComponent = async ({
    mountFn = shallowMountExtended,
    handlers = [],
    route = defaultRoute,
  } = {}) => {
    const apolloProvider = createMockApollo(handlers, resolvers(endpoint));
    router = createRouter();
    await router.push(route);

    wrapper = mountFn(YourWorkGroupsApp, { propsData: defaultPropsData, apolloProvider, router });
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    mockAxios.onGet(endpoint).replyOnce(200, dashboardGroupsResponse);
  });

  afterEach(() => {
    mockAxios.restore();
    window.gon = {};
  });

  it('renders TabsWithList component and passes correct props', async () => {
    await createComponent();

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
      userPreferencesSortKey: null,
    });
  });

  it('renders relative URL that supports relative_url_root', async () => {
    window.gon = { relative_url_root: '/gitlab' };

    await createComponent({ mountFn: mountExtended });
    await waitForPromises();

    const [expectedGroup] = dashboardGroupsResponse;

    expect(wrapper.findByRole('link', { name: expectedGroup.full_name }).attributes('href')).toBe(
      `/gitlab/${expectedGroup.full_path}`,
    );
  });

  it('correctly renders `Edit` action', async () => {
    await createComponent({ mountFn: mountExtended });

    await waitForPromises();

    await wrapper.findByRole('button', { name: 'Actions' }).trigger('click');

    expect(wrapper.findByRole('link', { name: 'Edit' }).attributes('href')).toBe(
      dashboardGroupsResponse[1].edit_path,
    );
  });
});
