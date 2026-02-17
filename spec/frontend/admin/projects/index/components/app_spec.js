import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { GlKeysetPagination } from '@gitlab/ui';
import adminProjectsGraphQlResponse from 'test_fixtures/graphql/admin/admin_projects.query.graphql.json';
import adminInactiveProjectsGraphQlResponse from 'test_fixtures/graphql/admin/inactive_admin_projects.query.graphql.json';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import TabView from '~/groups_projects/components/tab_view.vue';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import AdminProjectsApp from '~/admin/projects/index/components/app.vue';
import { programmingLanguages } from 'jest/groups_projects/components/mock_data';
import { createRouter } from '~/admin/projects/index/index';
import {
  FILTERED_SEARCH_TOKEN_LANGUAGE,
  FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
  FILTERED_SEARCH_TOKEN_VISIBILITY_LEVEL,
  FILTERED_SEARCH_TOKEN_NAMESPACE,
  FILTERED_SEARCH_TOKEN_REPOSITORY_CHECK_FAILED,
} from '~/groups_projects/constants';
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
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
  ADMIN_PROJECTS_ROUTE_NAME,
  INACTIVE_TAB,
} from '~/admin/projects/index/constants';
import adminProjectsQuery from '~/admin/projects/index/graphql/queries/admin_projects.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueRouter);
Vue.use(VueApollo);

describe('AdminProjectsApp', () => {
  let wrapper;

  const defaultPropsData = {
    programmingLanguages,
  };

  const defaultRoute = {
    name: ADMIN_PROJECTS_ROUTE_NAME,
  };

  const findTabsWithList = () => wrapper.findComponent(TabsWithList);

  const createComponent = async ({
    mountFn = shallowMountExtended,
    handlers = [],
    route = defaultRoute,
    features = {},
    stubs = {},
  } = {}) => {
    const apolloProvider = createMockApollo(handlers);
    const router = createRouter();
    await router.push(route);

    wrapper = mountFn(AdminProjectsApp, {
      propsData: defaultPropsData,
      apolloProvider,
      router,
      provide: { glFeatures: { customAbilityReadAdminProjects: false, ...features } },
      stubs,
    });
  };

  afterEach(() => {
    window.gon = {};
  });

  it('renders TabsWithList component and passes correct props', async () => {
    await createComponent();

    expect(findTabsWithList().props()).toMatchObject({
      tabs: ADMIN_PROJECTS_TABS,
      filteredSearchSupportedTokens: [
        FILTERED_SEARCH_TOKEN_LANGUAGE,
        FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
        FILTERED_SEARCH_TOKEN_VISIBILITY_LEVEL,
        FILTERED_SEARCH_TOKEN_NAMESPACE,
        FILTERED_SEARCH_TOKEN_REPOSITORY_CHECK_FAILED,
      ],
      filteredSearchTermKey: FILTERED_SEARCH_TERM_KEY,
      filteredSearchNamespace: FILTERED_SEARCH_NAMESPACE,
      filteredSearchRecentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_PROJECTS,
      timestampTypeMap: {
        [SORT_OPTION_CREATED.value]: TIMESTAMP_TYPE_CREATED_AT,
        [SORT_OPTION_UPDATED.value]: TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
      },
      firstTabRouteNames: FIRST_TAB_ROUTE_NAMES,
      initialSort: '',
      programmingLanguages: defaultPropsData.programmingLanguages,
      tabCountsQuery: projectCountsQuery,
      tabCountsQueryErrorMessage: 'An error occurred loading the project counts.',
    });
  });

  it('allows deleting immediately on Inactive tab', async () => {
    await createComponent({
      mountFn: mountExtended,
      handlers: [
        [adminProjectsQuery, jest.fn().mockResolvedValue(adminInactiveProjectsGraphQlResponse)],
      ],
      route: { name: INACTIVE_TAB.value },
    });

    await waitForPromises();
    await wrapper.findByRole('button', { name: 'Actions' }).trigger('click');

    expect(wrapper.findByRole('button', { name: 'Delete permanently' }).exists()).toBe(true);
  });

  it('uses adminShowPath for avatar link', async () => {
    await createComponent({
      mountFn: mountExtended,
      handlers: [[adminProjectsQuery, jest.fn().mockResolvedValue(adminProjectsGraphQlResponse)]],
    });
    await waitForPromises();

    const {
      data: {
        projects: {
          nodes: [expectedProject],
        },
      },
    } = adminProjectsGraphQlResponse;

    expect(
      wrapper.findByRole('link', { name: expectedProject.nameWithNamespace }).attributes('href'),
    ).toBe(expectedProject.adminShowPath);
  });

  it('uses adminEditPath for edit link', async () => {
    await createComponent({
      mountFn: mountExtended,
      handlers: [[adminProjectsQuery, jest.fn().mockResolvedValue(adminProjectsGraphQlResponse)]],
    });
    await waitForPromises();

    const {
      data: {
        projects: {
          nodes: [expectedProject],
        },
      },
    } = adminProjectsGraphQlResponse;

    await wrapper.findByRole('button', { name: 'Actions' }).trigger('click');

    expect(wrapper.findByRole('link', { name: 'Edit' }).attributes('href')).toBe(
      expectedProject.adminEditPath,
    );
  });

  it('uses keyset pagination', async () => {
    await createComponent({
      mountFn: mountExtended,
      handlers: [
        [
          adminProjectsQuery,
          jest.fn().mockResolvedValue({
            data: {
              projects: {
                ...adminProjectsGraphQlResponse.data.projects,
                nodes: adminProjectsGraphQlResponse.data.projects.nodes,
                pageInfo: {
                  ...adminProjectsGraphQlResponse.data.projects.pageInfo,
                  hasNextPage: true,
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

  it.each(ADMIN_PROJECTS_TABS)(
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
