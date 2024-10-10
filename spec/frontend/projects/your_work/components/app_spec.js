import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { GlBadge, GlTabs, GlFilteredSearchToken } from '@gitlab/ui';
import projectCountsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/project_counts.query.graphql.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import YourWorkProjectsApp from '~/projects/your_work/components/app.vue';
import TabView from '~/projects/your_work/components/tab_view.vue';
import { createRouter } from '~/projects/your_work';
import { stubComponent } from 'helpers/stub_component';
import {
  ROOT_ROUTE_NAME,
  DASHBOARD_ROUTE_NAME,
  PROJECTS_DASHBOARD_ROUTE_NAME,
  PROJECT_DASHBOARD_TABS,
  CONTRIBUTED_TAB,
  STARRED_TAB,
  PERSONAL_TAB,
  MEMBER_TAB,
  INACTIVE_TAB,
  FILTERED_SEARCH_TOKEN_LANGUAGE,
  FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
} from '~/projects/your_work/constants';
import { RECENT_SEARCHES_STORAGE_KEY_PROJECTS } from '~/filtered_search/recent_searches_storage_keys';
import {
  SORT_OPTIONS,
  SORT_OPTION_CREATED,
  SORT_OPTION_UPDATED,
  SORT_DIRECTION_DESC,
  SORT_DIRECTION_ASC,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
} from '~/projects/filtered_search_and_sort/constants';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import projectCountsQuery from '~/projects/your_work/graphql/queries/project_counts.query.graphql';
import { createAlert } from '~/alert';
import { ACCESS_LEVEL_OWNER_INTEGER } from '~/access_level/constants';
import { QUERY_PARAM_END_CURSOR, QUERY_PARAM_START_CURSOR } from '~/graphql_shared/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { programmingLanguages } from './mock_data';

jest.mock('~/alert');

Vue.use(VueRouter);
Vue.use(VueApollo);

const defaultRoute = {
  name: ROOT_ROUTE_NAME,
};

const defaultProvide = {
  initialSort: 'created_desc',
  programmingLanguages,
};

const searchTerm = 'foo bar';
const mockEndCursor = 'mockEndCursor';
const mockStartCursor = 'mockStartCursor';

describe('YourWorkProjectsApp', () => {
  let wrapper;
  let router;
  let mockApollo;

  const successHandler = jest.fn().mockResolvedValue(projectCountsGraphQlResponse);

  const createComponent = ({ handler = successHandler, route = defaultRoute } = {}) => {
    mockApollo = createMockApollo([[projectCountsQuery, handler]]);
    router = createRouter();
    router.push(route);

    wrapper = mountExtended(YourWorkProjectsApp, {
      apolloProvider: mockApollo,
      router,
      stubs: {
        TabView: stubComponent(TabView),
      },
      provide: defaultProvide,
    });
  };

  const findPageTitle = () => wrapper.find('h1');
  const findGlTabs = () => wrapper.findComponent(GlTabs);
  const findActiveTab = () => wrapper.findByRole('tab', { selected: true });
  const findTabByName = (name) =>
    wrapper.findAllByRole('tab').wrappers.find((tab) => tab.text().includes(name));
  const getTabCount = (tabName) => findTabByName(tabName).findComponent(GlBadge).text();
  const findFilteredSearchAndSort = () => wrapper.findComponent(FilteredSearchAndSort);
  const findTabView = () => wrapper.findComponent(TabView);

  afterEach(() => {
    router = null;
    mockApollo = null;
  });

  describe('template', () => {
    it('renders Vue app with Projects h1 tag', () => {
      createComponent();

      expect(findPageTitle().text()).toBe('Projects');
    });

    describe('when project counts are loading', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not show count badges', () => {
        expect(wrapper.findComponent(GlBadge).exists()).toBe(false);
      });
    });

    describe('when project counts are successfully retrieved', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('shows count badges', () => {
        expect(getTabCount('Contributed')).toBe('2');
        expect(getTabCount('Starred')).toBe('0');
        expect(getTabCount('Personal')).toBe('0');
        expect(getTabCount('Member')).toBe('2');
        expect(getTabCount('Inactive')).toBe('0');
      });
    });

    describe('when project counts are not successfully retrieved', () => {
      const error = new Error();

      beforeEach(async () => {
        createComponent({ handler: jest.fn().mockRejectedValue(error) });
        await waitForPromises();
      });

      it('displays error alert', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred loading the project counts.',
          error,
          captureError: true,
        });
      });

      it('does not show count badges', () => {
        expect(wrapper.findComponent(GlBadge).exists()).toBe(false);
      });
    });

    it('defaults to Contributed tab as active', () => {
      expect(findActiveTab().text()).toContain('Contributed');
    });

    it('renders filtered search bar with correct props', () => {
      createComponent();

      expect(findFilteredSearchAndSort().props()).toMatchObject({
        filteredSearchTokens: [
          {
            type: FILTERED_SEARCH_TOKEN_LANGUAGE,
            icon: 'lock',
            title: 'Language',
            token: GlFilteredSearchToken,
            unique: true,
            operators: [{ value: '=', description: 'is' }],
            options: [
              { value: '5', title: 'CSS' },
              { value: '8', title: 'CoffeeScript' },
            ],
          },
          {
            type: FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
            icon: 'user',
            title: 'Role',
            token: GlFilteredSearchToken,
            unique: true,
            operators: OPERATORS_IS,
            options: [
              {
                value: '50',
                title: 'Owner',
              },
            ],
          },
        ],
        filteredSearchQuery: {},
        filteredSearchTermKey: FILTERED_SEARCH_TERM_KEY,
        filteredSearchNamespace: FILTERED_SEARCH_NAMESPACE,
        filteredSearchRecentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_PROJECTS,
        sortOptions: SORT_OPTIONS,
        activeSortOption: SORT_OPTION_CREATED,
        isAscending: false,
      });
    });

    describe('when filtered search bar is submitted', () => {
      beforeEach(() => {
        createComponent();

        findFilteredSearchAndSort().vm.$emit('filter', { [FILTERED_SEARCH_TERM_KEY]: searchTerm });
      });

      it('updates query string', () => {
        expect(router.currentRoute.query).toEqual({ [FILTERED_SEARCH_TERM_KEY]: searchTerm });
      });
    });

    describe('when sort is changed', () => {
      beforeEach(() => {
        createComponent({
          route: {
            ...defaultRoute,
            query: {
              [FILTERED_SEARCH_TERM_KEY]: searchTerm,
              [QUERY_PARAM_END_CURSOR]: mockEndCursor,
            },
          },
        });

        findFilteredSearchAndSort().vm.$emit('sort-by-change', SORT_OPTION_UPDATED.value);
      });

      it('updates query string', () => {
        expect(router.currentRoute.query).toEqual({
          [FILTERED_SEARCH_TERM_KEY]: searchTerm,
          sort: `${SORT_OPTION_UPDATED.value}_${SORT_DIRECTION_DESC}`,
        });
      });
    });

    describe('when sort direction is changed', () => {
      beforeEach(() => {
        createComponent({
          route: {
            ...defaultRoute,
            query: {
              [FILTERED_SEARCH_TERM_KEY]: searchTerm,
              [QUERY_PARAM_END_CURSOR]: mockEndCursor,
            },
          },
        });

        findFilteredSearchAndSort().vm.$emit('sort-direction-change', true);
      });

      it('updates query string', () => {
        expect(router.currentRoute.query).toEqual({
          [FILTERED_SEARCH_TERM_KEY]: searchTerm,
          sort: `${SORT_OPTION_CREATED.value}_${SORT_DIRECTION_ASC}`,
        });
      });
    });
  });

  describe.each`
    name                             | expectedTab
    ${ROOT_ROUTE_NAME}               | ${CONTRIBUTED_TAB}
    ${DASHBOARD_ROUTE_NAME}          | ${CONTRIBUTED_TAB}
    ${PROJECTS_DASHBOARD_ROUTE_NAME} | ${CONTRIBUTED_TAB}
    ${CONTRIBUTED_TAB.value}         | ${CONTRIBUTED_TAB}
    ${STARRED_TAB.value}             | ${STARRED_TAB}
    ${PERSONAL_TAB.value}            | ${PERSONAL_TAB}
    ${MEMBER_TAB.value}              | ${MEMBER_TAB}
    ${INACTIVE_TAB.value}            | ${INACTIVE_TAB}
  `('onMount when route name is $name', ({ name, expectedTab }) => {
    const query = {
      sort: 'name_desc',
      [FILTERED_SEARCH_TERM_KEY]: 'foo',
      [FILTERED_SEARCH_TOKEN_LANGUAGE]: '8',
      [FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL]: ACCESS_LEVEL_OWNER_INTEGER,
      [QUERY_PARAM_END_CURSOR]: mockEndCursor,
      [QUERY_PARAM_START_CURSOR]: mockStartCursor,
    };

    beforeEach(() => {
      createComponent({
        route: { name, query },
      });
    });

    it('initializes to the correct tab', () => {
      expect(findActiveTab().text()).toContain(expectedTab.text);
    });

    it('renders `TabView` component and passes `tab` prop', () => {
      expect(findTabView().props('tab')).toMatchObject(expectedTab);
    });

    it('passes sorting, filtering, and pagination props', () => {
      expect(findTabView().props()).toMatchObject({
        sort: query.sort,
        filters: {
          [FILTERED_SEARCH_TERM_KEY]: query[FILTERED_SEARCH_TERM_KEY],
          [FILTERED_SEARCH_TOKEN_LANGUAGE]: query[FILTERED_SEARCH_TOKEN_LANGUAGE],
          [FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL]: query[FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL],
        },
        endCursor: mockEndCursor,
        startCursor: mockStartCursor,
      });
    });
  });

  describe('onTabUpdate', () => {
    describe('when tab is already active', () => {
      beforeEach(() => {
        createComponent();
        router.push = jest.fn();
      });

      it('does not push new route', async () => {
        findGlTabs().vm.$emit('input', 0);

        await nextTick();

        expect(router.push).not.toHaveBeenCalled();
      });
    });

    describe('when tab is a valid tab', () => {
      beforeEach(() => {
        createComponent();
        router.push = jest.fn();
      });

      it('pushes new route correctly', async () => {
        findGlTabs().vm.$emit('input', 2);

        await nextTick();

        expect(router.push).toHaveBeenCalledWith({ name: PROJECT_DASHBOARD_TABS[2].value });
      });
    });

    describe('when tab is an invalid tab', () => {
      beforeEach(() => {
        createComponent();
        router.push = jest.fn();
      });

      it('pushes new route with default Contributed tab', async () => {
        findGlTabs().vm.$emit('input', 100);

        await nextTick();

        expect(router.push).toHaveBeenCalledWith({ name: CONTRIBUTED_TAB.value });
      });
    });

    describe('when gon.relative_url_root is set', () => {
      beforeEach(() => {
        gon.relative_url_root = '/gitlab';
        createComponent();
        router.push = jest.fn();
      });

      it('pushes new route correctly and respects relative url', async () => {
        findGlTabs().vm.$emit('input', 3);

        await nextTick();

        expect(router.options.base).toBe('/gitlab');
        expect(router.push).toHaveBeenCalledWith({ name: PROJECT_DASHBOARD_TABS[3].value });
      });
    });
  });

  describe('when page is changed', () => {
    describe('when going to next page', () => {
      beforeEach(async () => {
        createComponent({
          route: defaultRoute,
        });

        await nextTick();

        findTabView().vm.$emit('page-change', {
          endCursor: mockEndCursor,
          startCursor: null,
          hasPreviousPage: true,
        });
      });

      it('sets `end_cursor` query string', () => {
        expect(router.currentRoute.query).toMatchObject({
          end_cursor: mockEndCursor,
        });
      });
    });

    describe('when going to previous page', () => {
      beforeEach(async () => {
        createComponent({
          route: {
            ...defaultRoute,
            query: {
              start_cursor: mockStartCursor,
              end_cursor: mockEndCursor,
            },
          },
        });

        await nextTick();

        findTabView().vm.$emit('page-change', {
          endCursor: null,
          startCursor: mockStartCursor,
          hasPreviousPage: true,
        });
      });

      it('sets `start_cursor` query string', () => {
        expect(router.currentRoute.query).toMatchObject({
          start_cursor: mockStartCursor,
        });
      });
    });
  });
});
