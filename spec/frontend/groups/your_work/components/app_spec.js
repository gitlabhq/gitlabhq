import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { GlKeysetPagination } from '@gitlab/ui';
import dashboardGroupsResponse from 'test_fixtures/groups/dashboard/index.json';
import YourWorkGroupsApp from '~/groups/your_work/components/app.vue';
import { createRouter } from '~/groups/your_work';
import groupCountsQuery from '~/groups/your_work/graphql/queries/group_counts.query.graphql';
import {
  FILTERED_SEARCH_NAMESPACE,
  FILTERED_SEARCH_TERM_KEY,
  FIRST_TAB_ROUTE_NAMES,
  GROUP_DASHBOARD_TABS,
  GROUPS_DASHBOARD_ROUTE_NAME,
  SORT_OPTION_CREATED,
  SORT_OPTION_UPDATED,
  SORT_OPTIONS,
} from '~/groups/your_work/constants';
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import TabView from '~/groups_projects/components/tab_view.vue';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import { RECENT_SEARCHES_STORAGE_KEY_GROUPS } from '~/filtered_search/recent_searches_storage_keys';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import axios from '~/lib/utils/axios_utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import { resolvers } from '~/vue_shared/components/groups_list/resolvers';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useConfigurePathHelpers } from 'helpers/configure_path_helpers';

Vue.use(VueApollo);
Vue.use(VueRouter);

describe('YourWorkGroupsApp', () => {
  let wrapper;
  let mockAxios;
  let router;

  const defaultPropsData = {
    initialSort: 'created_desc',
    canCreateGroup: true,
  };

  const endpoint = '/dashboard/groups.json';
  const defaultRoute = {
    name: GROUPS_DASHBOARD_ROUTE_NAME,
  };
  const mockGroup = dashboardGroupsResponse[1];

  const createComponent = async ({
    mountFn = shallowMountExtended,
    handlers = [],
    route = defaultRoute,
    stubs = {},
  } = {}) => {
    const apolloProvider = createMockApollo(handlers, resolvers(endpoint));
    router = createRouter();
    await router.push(route);

    wrapper = mountFn(YourWorkGroupsApp, {
      propsData: defaultPropsData,
      apolloProvider,
      router,
      stubs,
    });
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  it('renders TabsWithList component and passes correct props', async () => {
    mockAxios.onGet(endpoint).replyOnce(200, dashboardGroupsResponse);
    await createComponent();

    expect(wrapper.findComponent(TabsWithList).props()).toMatchObject({
      tabs: GROUP_DASHBOARD_TABS,
      filteredSearchTestid: null,
      filteredSearchSupportedTokens: [],
      filteredSearchTermKey: FILTERED_SEARCH_TERM_KEY,
      filteredSearchNamespace: FILTERED_SEARCH_NAMESPACE,
      filteredSearchRecentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_GROUPS,
      filteredSearchInputPlaceholder: 'Search',
      timestampTypeMap: {
        [SORT_OPTION_CREATED.value]: TIMESTAMP_TYPE_CREATED_AT,
        [SORT_OPTION_UPDATED.value]: TIMESTAMP_TYPE_UPDATED_AT,
      },
      firstTabRouteNames: FIRST_TAB_ROUTE_NAMES,
      initialSort: defaultPropsData.initialSort,
      programmingLanguages: [],
      eventTracking: {
        filteredSearch: {
          [FILTERED_SEARCH_TERM_KEY]: 'search_on_your_work_groups',
        },
        pagination: 'click_pagination_on_your_work_groups',
        tabs: 'click_tab_on_your_work_groups',
        sort: 'click_sort_on_your_work_groups',
        hoverStat: 'hover_stat_on_your_work_groups',
        hoverVisibility: 'hover_visibility_icon_on_your_work_groups',
        initialLoad: 'initial_load_on_your_work_groups',
        clickItem: 'click_group_on_your_work_groups',
        clickItemAfterFilter: 'click_group_after_filter_on_your_work_groups',
      },
      tabCountsQuery: groupCountsQuery,
      tabCountsQueryErrorMessage: 'An error occurred loading the group counts.',
      shouldUpdateActiveTabCountFromTabQuery: false,
      userPreferencesSortKey: null,
      sortStorageKey: 'groups',
    });
  });

  it('links to the "Explore groups" page', async () => {
    await createComponent({ mountFn: mountExtended });

    expect(wrapper.findByTestId('explore-groups-button').attributes('href')).toBe(
      '/explore/groups',
    );
  });

  describe('when relative_url_root is set', () => {
    useConfigurePathHelpers('/gitlab');

    it('renders group with relative URL prefix', async () => {
      mockAxios.onGet(endpoint).replyOnce(200, dashboardGroupsResponse);

      await createComponent({ mountFn: mountExtended });
      await waitForPromises();

      const [expectedGroup] = dashboardGroupsResponse;

      expect(wrapper.findByRole('link', { name: expectedGroup.full_name }).attributes('href')).toBe(
        `/gitlab/${expectedGroup.full_path}`,
      );
    });
  });

  it('correctly renders `Edit` action', async () => {
    mockAxios.onGet(endpoint).replyOnce(200, dashboardGroupsResponse);
    await createComponent({ mountFn: mountExtended });

    await waitForPromises();

    await wrapper.findByRole('button', { name: 'Actions' }).trigger('click');

    expect(wrapper.findByRole('link', { name: 'Edit' }).attributes('href')).toBe(
      mockGroup.edit_path,
    );
  });

  describe('when user does not have permission to edit', () => {
    beforeEach(async () => {
      mockAxios.onGet(endpoint).replyOnce(200, [{ ...mockGroup, can_edit: false, children: [] }]);
      await createComponent({ mountFn: mountExtended });
      await waitForPromises();
    });

    it('does not render `Edit` action', async () => {
      await wrapper.findByRole('button', { name: 'Actions' }).trigger('click');

      expect(wrapper.findByRole('link', { name: 'Edit' }).exists()).toBe(false);
    });
  });

  it('uses keyset pagination', async () => {
    mockAxios.onGet(endpoint).replyOnce(200, dashboardGroupsResponse, {
      'X-PER-PAGE': 20,
      'X-NEXT-PAGE': 'next-cursor',
      'X-PREV-PAGE': null,
    });
    await createComponent({ mountFn: mountExtended });
    await waitForPromises();

    expect(wrapper.findComponent(GlKeysetPagination).exists()).toBe(true);
  });

  it.each(GROUP_DASHBOARD_TABS)(
    'renders expected sort options and active sort option on $text tab',
    async (tab) => {
      await createComponent({
        mountFn: mountExtended,
        stubs: { TabView },
        route: { name: tab.value },
      });

      expect(wrapper.findComponent(FilteredSearchAndSort).props()).toMatchObject({
        sortOptions: SORT_OPTIONS,
        activeSortOption: SORT_OPTION_CREATED,
      });
    },
  );
});
