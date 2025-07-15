import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { GlEmptyState } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import AdminGroupsApp from '~/admin/groups/index/components/app.vue';
import { createRouter } from '~/admin/groups/index/index';
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
  ADMIN_GROUPS_ROUTE_NAME,
} from '~/admin/groups/index/constants';
import adminGroupCountsQuery from '~/admin/groups/index/graphql/queries/group_counts.query.graphql';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import adminGroupsQuery from '~/admin/groups/index/graphql/queries/groups.query.graphql';
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
  let mockApollo;

  const createComponent = async ({
    mountFn = shallowMountExtended,
    adminGroupsQueryHandler = jest.fn(),
    route = defaultRoute,
    stubs = {},
  } = {}) => {
    mockApollo = createMockApollo([[adminGroupsQuery, adminGroupsQueryHandler]]);
    const router = createRouter();
    await router.push(route);

    wrapper = mountFn(AdminGroupsApp, { stubs, apolloProvider: mockApollo, router });
  };

  const findTabByName = (name) =>
    wrapper.findAllByRole('tab').wrappers.find((tab) => tab.text().includes(name));
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  afterEach(() => {
    mockApollo = null;
  });

  it('renders TabsWithList component and passes correct props', async () => {
    await createComponent();

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

  describe('when there are no groups', () => {
    beforeEach(async () => {
      await createComponent({
        mountFn: mountExtended,
        adminGroupsQueryHandler: jest
          .fn()
          .mockResolvedValue({ data: { groups: { nodes: [], pageInfo: {} } } }),
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
});
