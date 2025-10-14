import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { GlPagination, GlKeysetPagination } from '@gitlab/ui';
import childrenResponse from 'test_fixtures/groups/children.json';
import inactiveChildrenResponse from 'test_fixtures/groups/inactive_children.json';
import sharedGroupsResponse from 'test_fixtures/graphql/groups/shared_groups.query.graphql.json';
import sharedProjectsResponse from 'test_fixtures/graphql/projects/shared_projects.query.graphql.json';
import GroupsShowApp from '~/groups/show/components/app.vue';
import sharedGroupsQuery from '~/groups/show/graphql/queries/shared_groups.query.graphql';
import sharedProjectsQuery from '~/groups/show/graphql/queries/shared_projects.query.graphql';
import NestedGroupsProjectsList from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list.vue';
import NestedGroupsProjectsListItem from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list_item.vue';
import SubgroupsAndProjectsEmptyState from '~/groups/components/empty_states/subgroups_and_projects_empty_state.vue';
import InactiveSubgroupsAndProjectsEmptyState from '~/groups/components/empty_states/inactive_subgroups_and_projects_empty_state.vue';
import SharedGroupsEmptyState from '~/groups/components/empty_states/shared_groups_empty_state.vue';
import SharedProjectsEmptyState from '~/groups/components/empty_states/shared_projects_empty_state.vue';
import { createRouter } from '~/groups/show';
import {
  SUBGROUPS_AND_PROJECTS_TAB,
  SORT_OPTIONS,
  SORT_OPTIONS_WITH_STARS,
  SORT_OPTION_UPDATED,
  SORT_OPTION_CREATED,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
  INACTIVE_TAB,
  SHARED_GROUPS_TAB,
  SHARED_PROJECTS_TAB,
} from '~/groups/show/constants';
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
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
    fullPath: 'foo/bar',
  };

  const defaultProvide = {
    newSubgroupPath: '/groups/new',
    newProjectPath: 'projects/new',
    emptyProjectsIllustration: '/assets/illustrations/empty-state/empty-projects-md.svg',
    canCreateSubgroups: false,
    canCreateProjects: false,
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

    wrapper = mountFn(GroupsShowApp, {
      propsData: defaultPropsData,
      provide: defaultProvide,
      apolloProvider,
      router,
    });
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
      tabs: [
        SUBGROUPS_AND_PROJECTS_TAB,
        { ...SHARED_PROJECTS_TAB, variables: { fullPath: defaultPropsData.fullPath } },
        { ...SHARED_GROUPS_TAB, variables: { fullPath: defaultPropsData.fullPath } },
        INACTIVE_TAB,
      ],
      filteredSearchSupportedTokens: [],
      filteredSearchTermKey: FILTERED_SEARCH_TERM_KEY,
      filteredSearchNamespace: FILTERED_SEARCH_NAMESPACE,
      filteredSearchRecentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_GROUPS,
      filteredSearchInputPlaceholder: 'Search (3 character minimum)',
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
      userPreferencesSortKey: 'projectsSort',
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

    describe('when user does not have permission to edit', () => {
      beforeEach(async () => {
        mockAxios.onGet(endpoint).replyOnce(200, [
          { ...mockGroup, can_edit: false, children: [] },
          { ...mockProject, can_edit: false },
        ]);
        await createComponent({ mountFn: mountExtended });
        await waitForPromises();
      });

      it('does not render `Edit` action on project', async () => {
        const listItem = findProjectsListItem(mockProject);

        await listItem.findByRole('button', { name: 'Actions' }).trigger('click');

        expect(listItem.findByRole('link', { name: 'Edit' }).exists()).toBe(false);
      });

      it('does not render `Edit` action on group', async () => {
        const listItem = findGroupsListItem(mockGroup);

        await listItem.findByRole('button', { name: 'Actions' }).trigger('click');

        expect(listItem.findByRole('link', { name: 'Edit' }).exists()).toBe(false);
      });
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

    describe('when there are no subgroups or projects', () => {
      beforeEach(async () => {
        mockAxios.onGet(endpoint).replyOnce(200, []);
        await createComponent({ mountFn: mountExtended });

        await waitForPromises();
      });

      it('renders empty state', () => {
        expect(wrapper.findComponent(SubgroupsAndProjectsEmptyState).exists()).toBe(true);
      });
    });

    it('renders expected sort options and active sort option', async () => {
      mockAxios.onGet(endpoint).replyOnce(200, childrenResponse);
      await createComponent({ mountFn: mountExtended });
      await waitForPromises();

      expect(wrapper.findComponent(FilteredSearchAndSort).props()).toMatchObject({
        sortOptions: SORT_OPTIONS_WITH_STARS,
        activeSortOption: SORT_OPTION_CREATED,
      });
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

    describe('when there are no inactive subgroups or projects', () => {
      beforeEach(async () => {
        mockAxios.onGet(endpoint).replyOnce(200, []);
        await createComponent({ mountFn: mountExtended, route });

        await waitForPromises();
      });

      it('renders empty state', () => {
        expect(wrapper.findComponent(InactiveSubgroupsAndProjectsEmptyState).exists()).toBe(true);
      });
    });

    it('renders expected sort options and active sort option', async () => {
      mockAxios.onGet(endpoint).replyOnce(200, inactiveChildrenResponse);
      await createComponent({ mountFn: mountExtended, route });
      await waitForPromises();

      expect(wrapper.findComponent(FilteredSearchAndSort).props()).toMatchObject({
        sortOptions: SORT_OPTIONS_WITH_STARS,
        activeSortOption: SORT_OPTION_CREATED,
      });
    });
  });

  describe('when on the Shared groups tab', () => {
    const route = { name: SHARED_GROUPS_TAB.value };
    const {
      data: {
        group: {
          sharedGroups: {
            nodes: [mockGroup],
          },
        },
      },
    } = sharedGroupsResponse;

    it('renders shared groups', async () => {
      await createComponent({
        mountFn: mountExtended,
        route,
        handlers: [[sharedGroupsQuery, jest.fn().mockResolvedValue(sharedGroupsResponse)]],
      });
      await waitForPromises();

      expect(wrapper.findByRole('link', { name: mockGroup.name }).exists()).toBe(true);
    });

    it('correctly renders `Edit` action', async () => {
      await createComponent({
        mountFn: mountExtended,
        route,
        handlers: [[sharedGroupsQuery, jest.fn().mockResolvedValue(sharedGroupsResponse)]],
      });
      await waitForPromises();

      await wrapper.findByRole('button', { name: 'Actions' }).trigger('click');

      expect(wrapper.findByRole('link', { name: 'Edit' }).attributes('href')).toBe(
        mockGroup.editPath,
      );
    });

    describe('when user does not have permission to edit', () => {
      beforeEach(async () => {
        await createComponent({
          mountFn: mountExtended,
          route,
          handlers: [
            [
              sharedGroupsQuery,
              jest.fn().mockResolvedValue({
                data: {
                  group: {
                    ...sharedGroupsResponse.data.group,
                    sharedGroups: {
                      ...sharedGroupsResponse.data.group.sharedGroups,
                      nodes: [
                        {
                          ...mockGroup,
                          userPermissions: { ...mockGroup.userPermissions, viewEditPage: false },
                        },
                      ],
                    },
                  },
                },
              }),
            ],
          ],
        });

        await waitForPromises();
      });

      it('does not render `Edit` action', async () => {
        await wrapper.findByRole('button', { name: 'Actions' }).trigger('click');

        expect(wrapper.findByRole('link', { name: 'Edit' }).exists()).toBe(false);
      });
    });

    it.each`
      sort              | expected
      ${'created_asc'}  | ${'CREATED_AT_ASC'}
      ${'created_desc'} | ${'CREATED_AT_DESC'}
      ${'updated_asc'}  | ${'UPDATED_AT_ASC'}
      ${'updated_desc'} | ${'UPDATED_AT_DESC'}
      ${'name_asc'}     | ${'NAME_ASC'}
      ${'name_desc'}    | ${'NAME_DESC'}
    `('correctly transforms $sort sort', async ({ sort, expected }) => {
      const handler = jest.fn().mockResolvedValue(sharedGroupsResponse);

      await createComponent({
        mountFn: mountExtended,
        route: { ...route, query: { sort } },
        handlers: [[sharedGroupsQuery, handler]],
      });
      await waitForPromises();

      expect(handler).toHaveBeenCalledWith(expect.objectContaining({ sort: expected }));
    });

    it('uses keyset pagination', async () => {
      await createComponent({
        mountFn: mountExtended,
        route,
        handlers: [
          [
            sharedGroupsQuery,
            jest.fn().mockResolvedValue({
              data: {
                group: {
                  ...sharedGroupsResponse.data.group,
                  sharedGroups: {
                    ...sharedGroupsResponse.data.group.sharedGroups,
                    nodes: sharedGroupsResponse.data.group.sharedGroups.nodes,
                    pageInfo: {
                      ...sharedGroupsResponse.data.group.sharedGroups.pageInfo,
                      hasNextPage: true,
                    },
                  },
                },
              },
            }),
          ],
        ],
      });

      await waitForPromises();

      expect(wrapper.findComponent(GlKeysetPagination).exists()).toBe(true);
    });

    describe('when there are no shared groups', () => {
      beforeEach(async () => {
        await createComponent({
          mountFn: mountExtended,
          route,
          handlers: [
            [
              sharedGroupsQuery,
              jest.fn().mockResolvedValue({
                data: {
                  group: {
                    ...sharedGroupsResponse.data.group,
                    sharedGroups: {
                      ...sharedGroupsResponse.data.group.sharedGroups,
                      nodes: [],
                    },
                  },
                },
              }),
            ],
          ],
        });

        await waitForPromises();
      });

      it('renders empty state', () => {
        expect(wrapper.findComponent(SharedGroupsEmptyState).exists()).toBe(true);
      });
    });

    it('renders expected sort options and active sort option', async () => {
      await createComponent({
        mountFn: mountExtended,
        route,
        handlers: [[sharedGroupsQuery, jest.fn().mockResolvedValue(sharedGroupsResponse)]],
      });
      await waitForPromises();

      expect(wrapper.findComponent(FilteredSearchAndSort).props()).toMatchObject({
        sortOptions: SORT_OPTIONS,
        activeSortOption: SORT_OPTION_CREATED,
      });
    });
  });

  describe('when on the Shared projects tab', () => {
    const route = { name: SHARED_PROJECTS_TAB.value };
    const {
      data: {
        group: {
          sharedProjects: {
            nodes: [mockProject],
          },
        },
      },
    } = sharedProjectsResponse;

    it('renders shared projects', async () => {
      await createComponent({
        mountFn: mountExtended,
        route,
        handlers: [[sharedProjectsQuery, jest.fn().mockResolvedValue(sharedProjectsResponse)]],
      });
      await waitForPromises();

      expect(wrapper.findByRole('link', { name: mockProject.name }).exists()).toBe(true);
    });

    it('correctly renders `Edit` action', async () => {
      await createComponent({
        mountFn: mountExtended,
        route,
        handlers: [[sharedProjectsQuery, jest.fn().mockResolvedValue(sharedProjectsResponse)]],
      });
      await waitForPromises();

      await wrapper.findByRole('button', { name: 'Actions' }).trigger('click');

      expect(wrapper.findByRole('link', { name: 'Edit' }).attributes('href')).toBe(
        mockProject.editPath,
      );
    });

    describe('when user does not have permission to edit', () => {
      beforeEach(async () => {
        await createComponent({
          mountFn: mountExtended,
          route,
          handlers: [
            [
              sharedProjectsQuery,
              jest.fn().mockResolvedValue({
                data: {
                  group: {
                    ...sharedProjectsResponse.data.group,
                    sharedProjects: {
                      ...sharedProjectsResponse.data.group.sharedProjects,
                      nodes: [
                        {
                          ...mockProject,
                          userPermissions: { ...mockProject.userPermissions, viewEditPage: false },
                        },
                      ],
                    },
                  },
                },
              }),
            ],
          ],
        });

        await waitForPromises();
      });

      it('does not render `Edit` action', async () => {
        await wrapper.findByRole('button', { name: 'Actions' }).trigger('click');

        expect(wrapper.findByRole('link', { name: 'Edit' }).exists()).toBe(false);
      });
    });

    it('uses keyset pagination', async () => {
      await createComponent({
        mountFn: mountExtended,
        route,
        handlers: [
          [
            sharedProjectsQuery,
            jest.fn().mockResolvedValue({
              data: {
                group: {
                  ...sharedProjectsResponse.data.group,
                  sharedProjects: {
                    ...sharedProjectsResponse.data.group.sharedProjects,
                    nodes: sharedProjectsResponse.data.group.sharedProjects.nodes,
                    pageInfo: {
                      ...sharedProjectsResponse.data.group.sharedProjects.pageInfo,
                      hasNextPage: true,
                    },
                  },
                },
              },
            }),
          ],
        ],
      });

      await waitForPromises();

      expect(wrapper.findComponent(GlKeysetPagination).exists()).toBe(true);
    });

    describe('when there are no shared projects', () => {
      beforeEach(async () => {
        await createComponent({
          mountFn: mountExtended,
          route,
          handlers: [
            [
              sharedProjectsQuery,
              jest.fn().mockResolvedValue({
                data: {
                  group: {
                    ...sharedProjectsResponse.data.group,
                    sharedProjects: {
                      ...sharedProjectsResponse.data.group.sharedProjects,
                      nodes: [],
                    },
                  },
                },
              }),
            ],
          ],
        });

        await waitForPromises();
      });

      it('renders empty state', () => {
        expect(wrapper.findComponent(SharedProjectsEmptyState).exists()).toBe(true);
      });
    });

    it('renders expected sort options and active sort option', async () => {
      await createComponent({
        mountFn: mountExtended,
        route,
        handlers: [[sharedProjectsQuery, jest.fn().mockResolvedValue(sharedProjectsResponse)]],
      });
      await waitForPromises();

      expect(wrapper.findComponent(FilteredSearchAndSort).props()).toMatchObject({
        sortOptions: SORT_OPTIONS,
        activeSortOption: SORT_OPTION_CREATED,
      });
    });
  });
});
