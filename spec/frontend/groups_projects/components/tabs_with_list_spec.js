import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { GlBadge, GlTabs, GlFilteredSearchToken } from '@gitlab/ui';
import projectCountsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/project_counts.query.graphql.json';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import TabView from '~/groups_projects/components/tab_view.vue';
import { createRouter } from '~/projects/your_work';
import { stubComponent } from 'helpers/stub_component';
import {
  ROOT_ROUTE_NAME,
  DASHBOARD_ROUTE_NAME,
  PROJECTS_DASHBOARD_ROUTE_NAME,
  PROJECT_DASHBOARD_TABS,
  FIRST_TAB_ROUTE_NAMES,
  CONTRIBUTED_TAB,
  STARRED_TAB,
  PERSONAL_TAB,
  MEMBER_TAB,
  INACTIVE_TAB,
} from '~/projects/your_work/constants';
import {
  FILTERED_SEARCH_TOKEN_LANGUAGE,
  FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
  SORT_DIRECTION_DESC,
  SORT_DIRECTION_ASC,
} from '~/groups_projects/constants';
import { RECENT_SEARCHES_STORAGE_KEY_PROJECTS } from '~/filtered_search/recent_searches_storage_keys';
import {
  SORT_OPTIONS,
  SORT_OPTION_CREATED,
  SORT_OPTION_UPDATED,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
} from '~/projects/filtered_search_and_sort/constants';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import projectCountsQuery from '~/projects/your_work/graphql/queries/project_counts.query.graphql';
import userPreferencesUpdateMutation from '~/groups_projects/graphql/mutations/user_preferences_update.mutation.graphql';
import { createAlert } from '~/alert';
import { ACCESS_LEVEL_OWNER_INTEGER } from '~/access_level/constants';
import { QUERY_PARAM_END_CURSOR, QUERY_PARAM_START_CURSOR } from '~/graphql_shared/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
} from '~/vue_shared/components/resource_lists/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { programmingLanguages } from './mock_data';

jest.mock('~/alert');
jest.mock('~/sentry/sentry_browser_wrapper');

Vue.use(VueRouter);
Vue.use(VueApollo);

const defaultRoute = {
  name: ROOT_ROUTE_NAME,
};

const defaultPropsData = {
  tabs: PROJECT_DASHBOARD_TABS,
  filteredSearchSupportedTokens: [
    FILTERED_SEARCH_TOKEN_LANGUAGE,
    FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
  ],
  filteredSearchTermKey: FILTERED_SEARCH_TERM_KEY,
  filteredSearchNamespace: FILTERED_SEARCH_NAMESPACE,
  filteredSearchRecentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_PROJECTS,
  sortOptions: SORT_OPTIONS,
  defaultSortOption: SORT_OPTION_UPDATED,
  timestampTypeMap: {
    [SORT_OPTION_CREATED.value]: TIMESTAMP_TYPE_CREATED_AT,
    [SORT_OPTION_UPDATED.value]: TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
  },
  firstTabRouteNames: FIRST_TAB_ROUTE_NAMES,
  initialSort: 'created_desc',
  programmingLanguages,
  eventTracking: {
    filteredSearch: {
      [FILTERED_SEARCH_TERM_KEY]: 'search_on_your_work_projects',
      [FILTERED_SEARCH_TOKEN_LANGUAGE]: 'filter_by_language_on_your_work_projects',
      [FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL]: 'filter_by_role_on_your_work_projects',
    },
    pagination: 'click_pagination_on_your_work_projects',
    tabs: 'click_tab_on_your_work_projects',
    sort: 'click_sort_on_your_work_projects',
  },
};

const { bindInternalEventDocument } = useMockInternalEventsTracking();

const searchTerm = 'foo bar';
const mockEndCursor = 'mockEndCursor';
const mockStartCursor = 'mockStartCursor';

describe('TabsWithList', () => {
  let wrapper;
  let router;
  let mockApollo;

  const successHandler = jest.fn().mockResolvedValue(projectCountsGraphQlResponse);
  const userPreferencesUpdateSuccessHandler = jest.fn().mockResolvedValue({
    data: {
      userPreferencesUpdate: {
        userPreferences: {
          projectsSort: 'NAME_DESC',
        },
      },
    },
  });

  const createComponent = async ({
    propsData = {},
    projectsCountHandler = successHandler,
    userPreferencesUpdateHandler = userPreferencesUpdateSuccessHandler,
    route = defaultRoute,
  } = {}) => {
    mockApollo = createMockApollo([
      [projectCountsQuery, projectsCountHandler],
      [userPreferencesUpdateMutation, userPreferencesUpdateHandler],
    ]);
    router = createRouter();
    await router.push(route);

    wrapper = mountExtended(TabsWithList, {
      apolloProvider: mockApollo,
      router,
      stubs: {
        TabView: stubComponent(TabView),
      },
      propsData: { ...defaultPropsData, ...propsData },
    });
  };

  const findGlTabs = () => wrapper.findComponent(GlTabs);
  const findActiveTab = () => wrapper.findByRole('tab', { selected: true });
  const findTabByName = (name) =>
    wrapper.findAllByRole('tab').wrappers.find((tab) => tab.text().includes(name));
  const getTabCount = (tabName) =>
    extendedWrapper(findTabByName(tabName)).findByTestId('tab-counter-badge').text();
  const findFilteredSearchAndSort = () => wrapper.findComponent(FilteredSearchAndSort);
  const findTabView = () => wrapper.findComponent(TabView);

  afterEach(() => {
    router = null;
    mockApollo = null;
  });

  describe('template', () => {
    describe('when project counts are loading', () => {
      it('does not show count badges', async () => {
        await createComponent();
        expect(wrapper.findComponent(GlBadge).exists()).toBe(false);
      });
    });

    describe('when project counts are successfully retrieved', () => {
      beforeEach(async () => {
        await createComponent();
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
        await createComponent({ projectsCountHandler: jest.fn().mockRejectedValue(error) });
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

    it('renders filtered search bar with correct props', async () => {
      await createComponent({
        propsData: {
          filteredSearchSupportedTokens: [FILTERED_SEARCH_TOKEN_LANGUAGE],
        },
      });

      expect(findFilteredSearchAndSort().props()).toMatchObject({
        filteredSearchTokens: [
          {
            type: FILTERED_SEARCH_TOKEN_LANGUAGE,
            icon: 'code',
            title: 'Language',
            token: GlFilteredSearchToken,
            unique: true,
            operators: [{ value: '=', description: 'is' }],
            options: [
              { value: '5', title: 'CSS' },
              { value: '8', title: 'CoffeeScript' },
            ],
          },
        ],
        filteredSearchQuery: {},
        filteredSearchTermKey: defaultPropsData.filteredSearchTermKey,
        filteredSearchNamespace: defaultPropsData.filteredSearchNamespace,
        filteredSearchRecentSearchesStorageKey:
          defaultPropsData.filteredSearchRecentSearchesStorageKey,
        sortOptions: defaultPropsData.sortOptions,
        activeSortOption: SORT_OPTION_CREATED,
        isAscending: false,
      });
    });

    describe('when filtered search bar is submitted', () => {
      beforeEach(async () => {
        await createComponent();
      });

      it('updates query string', async () => {
        findFilteredSearchAndSort().vm.$emit('filter', {
          [defaultPropsData.filteredSearchTermKey]: searchTerm,
        });
        await waitForPromises();

        expect(router.currentRoute.query).toEqual({
          [defaultPropsData.filteredSearchTermKey]: searchTerm,
        });
      });

      it('tracks all filter events when multiple filters are applied', async () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        findFilteredSearchAndSort().vm.$emit('filter', {
          [defaultPropsData.filteredSearchTermKey]: searchTerm,
          [FILTERED_SEARCH_TOKEN_LANGUAGE]: ['5'],
          [FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL]: ['50'],
        });
        await waitForPromises();

        expect(trackEventSpy).toHaveBeenCalledWith(
          'search_on_your_work_projects',
          { label: 'Contributed' },
          undefined,
        );
        expect(trackEventSpy).toHaveBeenCalledWith(
          'filter_by_language_on_your_work_projects',
          { label: 'Contributed', property: 'CSS' },
          undefined,
        );
        expect(trackEventSpy).toHaveBeenCalledWith(
          'filter_by_role_on_your_work_projects',
          { label: 'Contributed', property: 'Owner' },
          undefined,
        );
      });

      describe('when invalid filter option is used', () => {
        it('does not track events', async () => {
          const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

          findFilteredSearchAndSort().vm.$emit('filter', {
            [FILTERED_SEARCH_TOKEN_LANGUAGE]: ['51'],
          });
          await waitForPromises();

          expect(trackEventSpy).not.toHaveBeenCalled();
        });
      });
    });

    describe('when sort is changed', () => {
      let trackEventSpy;

      beforeEach(async () => {
        await createComponent({
          route: {
            ...defaultRoute,
            query: {
              [defaultPropsData.filteredSearchTermKey]: searchTerm,
              [QUERY_PARAM_END_CURSOR]: mockEndCursor,
            },
          },
        });

        trackEventSpy = bindInternalEventDocument(wrapper.element).trackEventSpy;

        findFilteredSearchAndSort().vm.$emit('sort-by-change', SORT_OPTION_UPDATED.value);
        await waitForPromises();
      });

      it('updates query string', () => {
        expect(router.currentRoute.query).toEqual({
          [defaultPropsData.filteredSearchTermKey]: searchTerm,
          sort: `${SORT_OPTION_UPDATED.value}_${SORT_DIRECTION_DESC}`,
        });
      });

      it('calls `userPreferencesUpdate` mutation with correct variables', () => {
        expect(userPreferencesUpdateSuccessHandler).toHaveBeenCalledWith({
          input: { projectsSort: 'LATEST_ACTIVITY_DESC' },
        });
      });

      it('does not call Sentry.captureException', () => {
        expect(Sentry.captureException).not.toHaveBeenCalled();
      });

      it('tracks event', () => {
        expect(trackEventSpy).toHaveBeenCalledWith(
          'click_sort_on_your_work_projects',
          { label: 'Contributed', property: `${SORT_OPTION_UPDATED.value}_${SORT_DIRECTION_DESC}` },
          undefined,
        );
      });
    });

    describe('when sort direction is changed', () => {
      let trackEventSpy;

      beforeEach(async () => {
        await createComponent({
          route: {
            ...defaultRoute,
            query: {
              [defaultPropsData.filteredSearchTermKey]: searchTerm,
              [QUERY_PARAM_END_CURSOR]: mockEndCursor,
            },
          },
        });

        trackEventSpy = bindInternalEventDocument(wrapper.element).trackEventSpy;

        findFilteredSearchAndSort().vm.$emit('sort-direction-change', true);
        await waitForPromises();
      });

      it('updates query string', () => {
        expect(router.currentRoute.query).toEqual({
          [defaultPropsData.filteredSearchTermKey]: searchTerm,
          sort: `${SORT_OPTION_CREATED.value}_${SORT_DIRECTION_ASC}`,
        });
      });

      it('calls `userPreferencesUpdate` mutation with correct variables', () => {
        expect(userPreferencesUpdateSuccessHandler).toHaveBeenCalledWith({
          input: { projectsSort: 'CREATED_ASC' },
        });
      });

      it('does not call Sentry.captureException', () => {
        expect(Sentry.captureException).not.toHaveBeenCalled();
      });

      it('tracks event', () => {
        expect(trackEventSpy).toHaveBeenCalledWith(
          'click_sort_on_your_work_projects',
          { label: 'Contributed', property: `${SORT_OPTION_CREATED.value}_${SORT_DIRECTION_ASC}` },
          undefined,
        );
      });
    });
  });

  describe('when `userPreferencesUpdate` mutation fails', () => {
    const error = new Error();

    beforeEach(async () => {
      await createComponent({ userPreferencesUpdateHandler: jest.fn().mockRejectedValue(error) });

      findFilteredSearchAndSort().vm.$emit('sort-by-change', SORT_OPTION_UPDATED.value);
      await waitForPromises();
    });

    it('captures error in Sentry', () => {
      expect(Sentry.captureException).toHaveBeenCalledWith(error);
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
      [defaultPropsData.filteredSearchTermKey]: 'foo',
      [FILTERED_SEARCH_TOKEN_LANGUAGE]: '8',
      [FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL]: ACCESS_LEVEL_OWNER_INTEGER,
      [QUERY_PARAM_END_CURSOR]: mockEndCursor,
      [QUERY_PARAM_START_CURSOR]: mockStartCursor,
    };

    beforeEach(async () => {
      await createComponent({
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
          [defaultPropsData.filteredSearchTermKey]: query[defaultPropsData.filteredSearchTermKey],
          [FILTERED_SEARCH_TOKEN_LANGUAGE]: query[FILTERED_SEARCH_TOKEN_LANGUAGE],
          [FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL]: query[FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL],
        },
        filteredSearchTermKey: defaultPropsData.filteredSearchTermKey,
        endCursor: mockEndCursor,
        startCursor: mockStartCursor,
      });
    });
  });

  describe('when sort query param is invalid', () => {
    beforeEach(async () => {
      await createComponent({
        route: {
          ...defaultRoute,
          query: {
            sort: 'foo_bar',
          },
        },
      });
    });

    it('falls back to initial sort', () => {
      expect(findTabView().props()).toMatchObject({
        sort: `${SORT_OPTION_CREATED.value}_${SORT_DIRECTION_DESC}`,
      });
    });
  });

  describe('when sort query param and initial sort are invalid', () => {
    beforeEach(async () => {
      await createComponent({
        propsData: { initialSort: 'foo_bar' },
        route: {
          ...defaultRoute,
          query: {
            sort: 'foo_bar',
          },
        },
      });
    });

    it('falls back to defaultSortOption prop ascending order', () => {
      expect(findTabView().props()).toMatchObject({
        sort: `${defaultPropsData.defaultSortOption.value}_${SORT_DIRECTION_ASC}`,
      });
    });
  });

  describe('onTabUpdate', () => {
    describe('when tab is already active', () => {
      beforeEach(async () => {
        await createComponent();
        router.push = jest.fn();
      });

      it('does not push new route', async () => {
        findGlTabs().vm.$emit('input', 0);

        await nextTick();

        expect(router.push).not.toHaveBeenCalled();
      });
    });

    describe('when tab is a valid tab', () => {
      beforeEach(async () => {
        await createComponent();
        router.push = jest.fn();
      });

      it('pushes new route correctly', async () => {
        findGlTabs().vm.$emit('input', 2);

        await nextTick();

        expect(router.push).toHaveBeenCalledWith({ name: PROJECT_DASHBOARD_TABS[2].value });
      });

      it('tracks event', () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        findGlTabs().vm.$emit('input', 2);

        expect(trackEventSpy).toHaveBeenCalledWith(
          'click_tab_on_your_work_projects',
          { label: PERSONAL_TAB.text },
          undefined,
        );
      });
    });

    describe('when tab is an invalid tab', () => {
      beforeEach(async () => {
        await createComponent();
        router.push = jest.fn();
      });

      it('pushes new route with default Contributed tab', async () => {
        findGlTabs().vm.$emit('input', 100);

        await nextTick();

        expect(router.push).toHaveBeenCalledWith({ name: CONTRIBUTED_TAB.value });
      });
    });

    describe('when gon.relative_url_root is set', () => {
      beforeEach(async () => {
        gon.relative_url_root = '/gitlab';
        await createComponent();
        router.push = jest.fn();
      });

      it('pushes new route correctly and respects relative url', async () => {
        findGlTabs().vm.$emit('input', 3);

        await nextTick();

        if (router.options.base) {
          // Vue router 3
          expect(router.options.base).toBe('/gitlab');
        } else {
          // Vue router 4
          expect(router.currentRoute.href).toBe('/gitlab/');
        }

        expect(router.push).toHaveBeenCalledWith({ name: PROJECT_DASHBOARD_TABS[3].value });
      });
    });
  });

  describe('when page is changed', () => {
    let trackEventSpy;

    describe('when going to next page', () => {
      beforeEach(async () => {
        await createComponent({
          route: defaultRoute,
        });

        await nextTick();

        trackEventSpy = bindInternalEventDocument(wrapper.element).trackEventSpy;

        findTabView().vm.$emit('page-change', {
          endCursor: mockEndCursor,
          startCursor: null,
          hasPreviousPage: true,
        });

        await waitForPromises();
      });

      it('sets `end_cursor` query string', () => {
        expect(router.currentRoute.query).toMatchObject({
          end_cursor: mockEndCursor,
        });
      });

      it('tracks event', () => {
        expect(trackEventSpy).toHaveBeenCalledWith(
          'click_pagination_on_your_work_projects',
          { label: 'Contributed', property: 'next' },
          undefined,
        );
      });
    });

    describe('when going to previous page', () => {
      beforeEach(async () => {
        await createComponent({
          route: {
            ...defaultRoute,
            query: {
              start_cursor: mockStartCursor,
              end_cursor: mockEndCursor,
            },
          },
        });

        await nextTick();

        trackEventSpy = bindInternalEventDocument(wrapper.element).trackEventSpy;

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

      it('tracks event', () => {
        expect(trackEventSpy).toHaveBeenCalledWith(
          'click_pagination_on_your_work_projects',
          { label: 'Contributed', property: 'previous' },
          undefined,
        );
      });
    });
  });

  describe.each`
    sort                      | expectedTimestampType
    ${'name_asc'}             | ${undefined}
    ${'name_desc'}            | ${undefined}
    ${'created_asc'}          | ${TIMESTAMP_TYPE_CREATED_AT}
    ${'created_desc'}         | ${TIMESTAMP_TYPE_CREATED_AT}
    ${'latest_activity_asc'}  | ${TIMESTAMP_TYPE_LAST_ACTIVITY_AT}
    ${'latest_activity_desc'} | ${TIMESTAMP_TYPE_LAST_ACTIVITY_AT}
    ${'stars_asc'}            | ${undefined}
    ${'stars_desc'}           | ${undefined}
  `('when sort is $sort', ({ sort, expectedTimestampType }) => {
    beforeEach(async () => {
      await createComponent({
        route: {
          ...defaultRoute,
          query: {
            sort,
          },
        },
      });
    });

    it('correctly passes timestampType prop to TabView component', () => {
      expect(findTabView().props('timestampType')).toBe(expectedTimestampType);
    });
  });
});
