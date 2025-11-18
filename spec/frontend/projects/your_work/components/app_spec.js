import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { GlKeysetPagination } from '@gitlab/ui';
import contributedProjectsQueryResponse from 'test_fixtures/graphql/projects/your_work/contributed_projects.query.graphql.json';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import YourWorkProjectsApp from '~/projects/your_work/components/app.vue';
import userProjectsQuery from '~/projects/your_work/graphql/queries/user_projects.query.graphql';
import {
  PROJECT_DASHBOARD_TABS,
  FIRST_TAB_ROUTE_NAMES,
  PROJECTS_DASHBOARD_ROUTE_NAME,
} from '~/projects/your_work/constants';
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import TabView from '~/groups_projects/components/tab_view.vue';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import {
  FILTERED_SEARCH_TOKEN_LANGUAGE,
  FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
} from '~/groups_projects/constants';
import { RECENT_SEARCHES_STORAGE_KEY_PROJECTS } from '~/filtered_search/recent_searches_storage_keys';
import {
  SORT_OPTIONS,
  SORT_OPTION_UPDATED,
  SORT_OPTION_CREATED,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
} from '~/projects/filtered_search_and_sort/constants';
import projectCountsQuery from '~/projects/your_work/graphql/queries/project_counts.query.graphql';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
} from '~/vue_shared/components/resource_lists/constants';
import { createRouter } from '~/projects/your_work';
import createMockApollo from 'helpers/mock_apollo_helper';
import { programmingLanguages } from 'jest/groups_projects/components/mock_data';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);
Vue.use(VueRouter);

describe('YourWorkProjectsApp', () => {
  let wrapper;
  let router;

  const defaultPropsData = {
    initialSort: 'created_desc',
    programmingLanguages,
  };

  const defaultRoute = {
    name: PROJECTS_DASHBOARD_ROUTE_NAME,
  };

  const {
    data: {
      currentUser: {
        contributedProjects: {
          nodes: [mockProject],
        },
      },
    },
  } = contributedProjectsQueryResponse;

  const createComponent = async ({
    mountFn = shallowMountExtended,
    handlers = [],
    route = defaultRoute,
    stubs = {},
  } = {}) => {
    const apolloProvider = createMockApollo(handlers);
    router = createRouter();
    await router.push(route);

    wrapper = mountFn(YourWorkProjectsApp, {
      propsData: defaultPropsData,
      apolloProvider,
      router,
      stubs,
    });
  };

  const openActions = async () => {
    await wrapper.findByRole('button', { name: 'Actions' }).trigger('click');
  };

  afterEach(() => {
    window.gon = {};
  });

  it('renders TabsWithList component and passes correct props', async () => {
    await createComponent();

    expect(wrapper.findComponent(TabsWithList).props()).toEqual({
      tabs: PROJECT_DASHBOARD_TABS,
      filteredSearchSupportedTokens: [
        FILTERED_SEARCH_TOKEN_LANGUAGE,
        FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
      ],
      filteredSearchTermKey: FILTERED_SEARCH_TERM_KEY,
      filteredSearchNamespace: FILTERED_SEARCH_NAMESPACE,
      filteredSearchRecentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_PROJECTS,
      filteredSearchInputPlaceholder: 'Filter or search (3 character minimum)',
      timestampTypeMap: {
        [SORT_OPTION_CREATED.value]: TIMESTAMP_TYPE_CREATED_AT,
        [SORT_OPTION_UPDATED.value]: TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
      },
      firstTabRouteNames: FIRST_TAB_ROUTE_NAMES,
      initialSort: defaultPropsData.initialSort,
      programmingLanguages: defaultPropsData.programmingLanguages,
      eventTracking: {
        filteredSearch: {
          [FILTERED_SEARCH_TERM_KEY]: 'search_on_your_work_projects',
          [FILTERED_SEARCH_TOKEN_LANGUAGE]: 'filter_by_language_on_your_work_projects',
          [FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL]: 'filter_by_role_on_your_work_projects',
        },
        pagination: 'click_pagination_on_your_work_projects',
        tabs: 'click_tab_on_your_work_projects',
        sort: 'click_sort_on_your_work_projects',
        clickStat: 'click_stat_on_your_work_projects',
        hoverStat: 'hover_stat_on_your_work_projects',
        hoverVisibility: 'hover_visibility_icon_on_your_work_projects',
        initialLoad: 'initial_load_on_your_work_projects',
        clickItemAfterFilter: 'click_project_after_filter_on_your_work_projects',
        clickTopic: 'click_topic_on_your_work_projects',
      },
      tabCountsQuery: projectCountsQuery,
      tabCountsQueryErrorMessage: 'An error occurred loading the project counts.',
      shouldUpdateActiveTabCountFromTabQuery: true,
      userPreferencesSortKey: 'projectsSort',
    });
  });

  it('correctly renders `Edit` action', async () => {
    await createComponent({
      mountFn: mountExtended,
      handlers: [
        [userProjectsQuery, jest.fn().mockResolvedValue(contributedProjectsQueryResponse)],
      ],
    });
    await waitForPromises();

    await openActions();

    expect(wrapper.findByRole('link', { name: 'Edit' }).attributes('href')).toBe(
      mockProject.editPath,
    );
  });

  describe('when user does not have permission to edit', () => {
    beforeEach(async () => {
      await createComponent({
        mountFn: mountExtended,
        handlers: [
          [
            userProjectsQuery,
            jest.fn().mockResolvedValue({
              data: {
                currentUser: {
                  ...contributedProjectsQueryResponse.data.currentUser,
                  contributedProjects: {
                    ...contributedProjectsQueryResponse.data.currentUser.contributedProjects,
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
      await openActions();

      expect(wrapper.findByRole('link', { name: 'Edit' }).exists()).toBe(false);
    });
  });

  it('renders relative URL that supports relative_url_root', async () => {
    window.gon = { relative_url_root: '/gitlab' };

    await createComponent({
      mountFn: mountExtended,
      handlers: [
        [userProjectsQuery, jest.fn().mockResolvedValue(contributedProjectsQueryResponse)],
      ],
    });
    await waitForPromises();

    expect(
      wrapper.findByRole('link', { name: mockProject.nameWithNamespace }).attributes('href'),
    ).toBe(`/gitlab/${mockProject.fullPath}`);
  });

  it('uses keyset pagination', async () => {
    await createComponent({
      mountFn: mountExtended,
      handlers: [
        [
          userProjectsQuery,
          jest.fn().mockResolvedValue({
            data: {
              currentUser: {
                ...contributedProjectsQueryResponse.data.currentUser,
                contributedProjects: {
                  ...contributedProjectsQueryResponse.data.currentUser.contributedProjects,
                  nodes:
                    contributedProjectsQueryResponse.data.currentUser.contributedProjects.nodes,
                  pageInfo: {
                    ...contributedProjectsQueryResponse.data.currentUser.contributedProjects
                      .pageInfo,
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

  it.each(PROJECT_DASHBOARD_TABS)(
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
