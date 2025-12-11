import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { GlEmptyState, GlKeysetPagination } from '@gitlab/ui';
import adminInactiveGroupsGraphQlResponse from 'test_fixtures/graphql/admin/inactive_admin_groups.query.graphql.json';
import adminGroupsGraphQlResponse from 'test_fixtures/graphql/admin/admin_groups.query.graphql.json';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import AdminGroupsApp from '~/admin/groups/index/components/app.vue';
import { createRouter } from '~/admin/groups/index/index';
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import TabView from '~/groups_projects/components/tab_view.vue';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import { RECENT_SEARCHES_STORAGE_KEY_GROUPS } from '~/filtered_search/recent_searches_storage_keys';
import {
  SORT_OPTIONS,
  SORT_OPTION_UPDATED,
  SORT_OPTION_CREATED,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
  ADMIN_GROUPS_TABS,
  FIRST_TAB_ROUTE_NAMES,
  ADMIN_GROUPS_ROUTE_NAME,
  INACTIVE_TAB,
} from '~/admin/groups/index/constants';
import adminGroupCountsQuery from '~/admin/groups/index/graphql/queries/group_counts.query.graphql';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import adminGroupsQuery from '~/admin/groups/index/graphql/queries/admin_groups.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock(
  '@gitlab/svgs/dist/illustrations/empty-state/empty-groups-md.svg?url',
  () => 'empty-groups-mocked-illustration',
);

Vue.use(VueRouter);
Vue.use(VueApollo);

const defaultRoute = {
  name: ADMIN_GROUPS_ROUTE_NAME,
};

describe('AdminGroupsApp', () => {
  let wrapper;

  const createComponent = async ({
    mountFn = shallowMountExtended,
    handlers = [],
    route = defaultRoute,
    stubs = {},
  } = {}) => {
    const apolloProvider = createMockApollo(handlers);
    const router = createRouter();
    await router.push(route);

    wrapper = mountFn(AdminGroupsApp, {
      apolloProvider,
      router,
      stubs,
    });
  };

  const findTabsWithList = () => wrapper.findComponent(TabsWithList);
  const findTabByName = (name) =>
    wrapper.findAllByRole('tab').wrappers.find((tab) => tab.text().includes(name));
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  afterEach(() => {
    window.gon = {};
  });

  it('renders TabsWithList component and passes correct props', async () => {
    await createComponent();

    expect(findTabsWithList().props()).toMatchObject({
      tabs: ADMIN_GROUPS_TABS,
      filteredSearchTestid: 'admin-groups-filtered-search-and-sort',
      filteredSearchTermKey: FILTERED_SEARCH_TERM_KEY,
      filteredSearchNamespace: FILTERED_SEARCH_NAMESPACE,
      filteredSearchRecentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_GROUPS,
      filteredSearchInputPlaceholder: 'Search (3 character minimum)',
      timestampTypeMap: {
        [SORT_OPTION_CREATED.value]: TIMESTAMP_TYPE_CREATED_AT,
        [SORT_OPTION_UPDATED.value]: TIMESTAMP_TYPE_UPDATED_AT,
      },
      initialSort: '',
      shouldUpdateActiveTabCountFromTabQuery: true,
      tabCountsQuery: adminGroupCountsQuery,
      tabCountsQueryErrorMessage: 'An error occurred loading the group counts.',
      firstTabRouteNames: FIRST_TAB_ROUTE_NAMES,
    });
  });

  it('uses adminShowPath for avatar link', async () => {
    await createComponent({
      mountFn: mountExtended,
      handlers: [[adminGroupsQuery, jest.fn().mockResolvedValue(adminGroupsGraphQlResponse)]],
    });
    await waitForPromises();

    const {
      data: {
        groups: {
          nodes: [expectedGroup],
        },
      },
    } = adminGroupsGraphQlResponse;

    expect(wrapper.findByRole('link', { name: expectedGroup.fullName }).attributes('href')).toBe(
      expectedGroup.adminShowPath,
    );
  });

  it('uses adminEditPath for edit link', async () => {
    await createComponent({
      mountFn: mountExtended,
      handlers: [[adminGroupsQuery, jest.fn().mockResolvedValue(adminGroupsGraphQlResponse)]],
    });
    await waitForPromises();

    const {
      data: {
        groups: {
          nodes: [expectedGroup],
        },
      },
    } = adminGroupsGraphQlResponse;

    await wrapper.findByRole('button', { name: 'Actions' }).trigger('click');

    expect(wrapper.findByRole('link', { name: 'Edit' }).attributes('href')).toBe(
      expectedGroup.adminEditPath,
    );
  });

  it('uses keyset pagination', async () => {
    await createComponent({
      mountFn: mountExtended,
      handlers: [
        [
          adminGroupsQuery,
          jest.fn().mockResolvedValue({
            data: {
              groups: {
                ...adminGroupsGraphQlResponse.data.groups,
                nodes: adminGroupsGraphQlResponse.data.groups.nodes,
                pageInfo: { ...adminGroupsGraphQlResponse.data.groups.pageInfo, hasNextPage: true },
              },
            },
          }),
        ],
      ],
    });

    await waitForPromises();

    expect(wrapper.findComponent(GlKeysetPagination).exists()).toBe(true);
  });

  it('allows deleting immediately on Inactive tab', async () => {
    window.gon = { allow_immediate_namespaces_deletion: true };

    await createComponent({
      mountFn: mountExtended,
      handlers: [
        [adminGroupsQuery, jest.fn().mockResolvedValue(adminInactiveGroupsGraphQlResponse)],
      ],
      route: { name: INACTIVE_TAB.value },
    });

    await waitForPromises();
    await wrapper.findByRole('button', { name: 'Actions' }).trigger('click');

    expect(wrapper.findByRole('button', { name: 'Delete immediately' }).exists()).toBe(true);
  });

  describe('when there are no groups', () => {
    beforeEach(async () => {
      await createComponent({
        mountFn: mountExtended,
        handlers: [
          [
            adminGroupsQuery,
            jest.fn().mockResolvedValue({ data: { groups: { nodes: [], pageInfo: {} } } }),
          ],
        ],
      });

      await waitForPromises();
    });

    it('renders empty state on Active tab', () => {
      expect(findEmptyState().props()).toMatchObject({
        title: "You don't have any active groups yet.",
        description:
          'A group is a collection of several projects. If you organize your projects under a group, it works like a folder.',
        svgPath: 'empty-groups-mocked-illustration',
      });
    });

    it('renders empty state on Inactive tab', async () => {
      await findTabByName('Inactive').trigger('click');
      await waitForPromises();

      expect(findEmptyState().props()).toMatchObject({
        title: "You don't have any inactive groups.",
        description: 'Groups that are archived or pending deletion will appear here.',
        svgPath: 'empty-groups-mocked-illustration',
      });
    });
  });

  it.each(ADMIN_GROUPS_TABS)(
    'renders expected sort options and active sort option on $text tab',
    async (tab) => {
      await createComponent({
        mountFn: mountExtended,
        stubs: { TabView },
        route: { name: tab.value },
      });

      expect(wrapper.findComponent(FilteredSearchAndSort).props()).toMatchObject({
        sortOptions: SORT_OPTIONS,
        activeSortOption: SORT_OPTION_UPDATED,
      });
    },
  );
});
