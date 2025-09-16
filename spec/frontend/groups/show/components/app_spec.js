import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { GlPagination } from '@gitlab/ui';
import childrenResponse from 'test_fixtures/groups/children.json';
import inactiveChildrenResponse from 'test_fixtures/groups/inactive_children.json';
import GroupsShowApp from '~/groups/show/components/app.vue';
import NestedGroupsProjectsList from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list.vue';
import NestedGroupsProjectsListItem from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list_item.vue';
import { createRouter } from '~/groups/show';
import {
  GROUPS_SHOW_TABS,
  SUBGROUPS_AND_PROJECTS_TAB,
  SORT_OPTIONS,
  SORT_OPTION_UPDATED,
  SORT_OPTION_CREATED,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
  INACTIVE_TAB,
} from '~/groups/show/constants';
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import { RECENT_SEARCHES_STORAGE_KEY_GROUPS } from '~/filtered_search/recent_searches_storage_keys';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import axios from '~/lib/utils/axios_utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import { resolvers } from '~/groups/show/graphql/resolvers';
import {
  shallowMountExtended,
  mountExtended,
  extendedWrapper,
} from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);
Vue.use(VueRouter);
// We need to globally render components to avoid circular references
// https://v2.vuejs.org/v2/guide/components-edge-cases.html#Circular-References-Between-Components
Vue.component('NestedGroupsProjectsList', NestedGroupsProjectsList);
Vue.component('NestedGroupsProjectsListItem', NestedGroupsProjectsListItem);

describe('GroupsShowApp', () => {
  let wrapper;
  let mockAxios;
  let router;

  const defaultPropsData = {
    initialSort: 'created_desc',
  };

  const endpoint = '/dashboard/groups.json';
  const defaultRoute = {
    name: SUBGROUPS_AND_PROJECTS_TAB.value,
  };

  const createComponent = async ({
    mountFn = shallowMountExtended,
    handlers = [],
    route = defaultRoute,
  } = {}) => {
    const apolloProvider = createMockApollo(handlers, resolvers(endpoint));
    router = createRouter();
    await router.push(route);

    wrapper = mountFn(GroupsShowApp, { propsData: defaultPropsData, apolloProvider, router });
  };

  const findGroupsListItem = (group) =>
    extendedWrapper(wrapper.findByTestId(`groups-list-item-${group.id}`));
  const findProjectsListItem = (project) =>
    extendedWrapper(wrapper.findByTestId(`projects-list-item-${project.id}`));

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
    window.gon = {};
  });

  it('renders TabsWithList component and passes correct props', async () => {
    mockAxios.onGet(endpoint).replyOnce(200, childrenResponse);
    await createComponent();

    expect(wrapper.findComponent(TabsWithList).props()).toEqual({
      tabs: GROUPS_SHOW_TABS,
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
      tabCountsQuery: {},
      tabCountsQueryErrorMessage: 'An error occurred loading the tab counts.',
      eventTracking: {},
      shouldUpdateActiveTabCountFromTabQuery: false,
      userPreferencesSortKey: null,
    });
  });

  describe('when on Subgroups and projects tab', () => {
    const [mockProject, , mockGroup] = childrenResponse;

    it('renders project with relative URL that supports relative_url_root', async () => {
      window.gon = { relative_url_root: '/gitlab' };
      mockAxios.onGet(endpoint).replyOnce(200, childrenResponse);

      await createComponent({ mountFn: mountExtended });
      await waitForPromises();

      expect(wrapper.findByRole('link', { name: mockProject.name }).attributes('href')).toBe(
        `/gitlab/${mockProject.full_path}`,
      );
    });

    it('renders group with relative URL that supports relative_url_root', async () => {
      window.gon = { relative_url_root: '/gitlab' };
      mockAxios.onGet(endpoint).replyOnce(200, childrenResponse);

      await createComponent({ mountFn: mountExtended });
      await waitForPromises();

      expect(wrapper.findByRole('link', { name: mockGroup.name }).attributes('href')).toBe(
        `/gitlab/${mockGroup.full_path}`,
      );
    });

    it('correctly renders `Edit` action on project', async () => {
      mockAxios.onGet(endpoint).replyOnce(200, childrenResponse);
      await createComponent({ mountFn: mountExtended });

      await waitForPromises();

      const listItem = findProjectsListItem(mockProject);

      await listItem.findByRole('button', { name: 'Actions' }).trigger('click');

      expect(listItem.findByRole('link', { name: 'Edit' }).attributes('href')).toBe(
        mockProject.edit_path,
      );
    });

    it('correctly renders `Edit` action on group', async () => {
      mockAxios.onGet(endpoint).replyOnce(200, childrenResponse);
      await createComponent({ mountFn: mountExtended });

      await waitForPromises();

      const listItem = findGroupsListItem(mockGroup);

      await listItem.findByRole('button', { name: 'Actions' }).trigger('click');

      expect(listItem.findByRole('link', { name: 'Edit' }).attributes('href')).toBe(
        mockGroup.edit_path,
      );
    });

    it('uses offset pagination', async () => {
      mockAxios.onGet(endpoint).replyOnce(200, childrenResponse, {
        'X-PER-PAGE': 20,
        'X-PAGE': 1,
        'X-TOTAL': 25,
        'X-TOTAL-PAGES': 2,
        'X-NEXT-PAGE': 2,
        'X-PREV-PAGE': null,
      });
      await createComponent({ mountFn: mountExtended });
      await waitForPromises();

      expect(wrapper.findComponent(GlPagination).exists()).toBe(true);
    });
  });

  describe('when on the Inactive tab', () => {
    const route = { name: INACTIVE_TAB.value };
    const [mockGroup] = inactiveChildrenResponse;
    const {
      children: [mockSubgroup, mockProject],
    } = mockGroup;

    it('renders inactive subgroups and projects', async () => {
      mockAxios.onGet(endpoint).replyOnce(200, inactiveChildrenResponse);
      await createComponent({ mountFn: mountExtended, route });
      await waitForPromises();
      await wrapper.findByTestId('nested-groups-project-list-item-toggle-button').trigger('click');

      expect(wrapper.findByRole('link', { name: mockGroup.name }).exists()).toBe(true);
      expect(wrapper.findByRole('link', { name: mockSubgroup.name }).exists()).toBe(true);
      expect(wrapper.findByRole('link', { name: mockProject.name }).exists()).toBe(true);
    });

    it('uses offset pagination', async () => {
      mockAxios.onGet(endpoint).replyOnce(200, childrenResponse, {
        'X-PER-PAGE': 20,
        'X-PAGE': 1,
        'X-TOTAL': 25,
        'X-TOTAL-PAGES': 2,
        'X-NEXT-PAGE': 2,
        'X-PREV-PAGE': null,
      });
      await createComponent({ mountFn: mountExtended, route });
      await waitForPromises();

      expect(wrapper.findComponent(GlPagination).exists()).toBe(true);
    });
  });
});
