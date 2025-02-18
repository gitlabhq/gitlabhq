import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import Vue from 'vue';
import { GlCollapsibleListbox } from '@gitlab/ui';
import App from '~/organizations/groups_and_projects/components/app.vue';
import GroupsView from '~/organizations/shared/components/groups_view.vue';
import ProjectsView from '~/organizations/shared/components/projects_view.vue';
import NewGroupButton from '~/organizations/shared/components/new_group_button.vue';
import NewProjectButton from '~/organizations/shared/components/new_project_button.vue';
import {
  RESOURCE_TYPE_GROUPS,
  RESOURCE_TYPE_PROJECTS,
  SORT_ITEM_NAME,
  SORT_ITEM_CREATED_AT,
  SORT_DIRECTION_DESC,
  SORT_DIRECTION_ASC,
} from '~/organizations/shared/constants';
import {
  SORT_ITEMS,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
} from '~/organizations/groups_and_projects/constants';
import {
  RECENT_SEARCHES_STORAGE_KEY_GROUPS,
  RECENT_SEARCHES_STORAGE_KEY_PROJECTS,
} from '~/filtered_search/recent_searches_storage_keys';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import { createRouter } from '~/organizations/groups_and_projects';
import userPreferencesUpdate from '~/organizations/groups_and_projects/graphql/mutations/user_preferences_update.mutation.graphql';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/sentry/sentry_browser_wrapper');

Vue.use(VueApollo);
Vue.use(VueRouter);

describe('GroupsAndProjectsApp', () => {
  const mockEndCursor = 'mockEndCursor';
  const mockStartCursor = 'mockStartCursor';
  const defaultProvide = {
    userPreferenceSortName: SORT_ITEM_NAME.value,
    userPreferenceSortDirection: SORT_DIRECTION_ASC,
    userPreferenceDisplay: null,
  };
  const userPreferencesUpdateSuccessHandler = jest.fn().mockResolvedValue({
    data: {
      userPreferencesUpdate: {
        userPreferences: {
          organizationGroupsProjectsSort: 'updated_asc',
          organizationGroupsProjectsDisplay: 'PROJECTS',
        },
      },
    },
  });

  let wrapper;
  let mockApollo;
  let router;

  const createComponent = async ({
    routeQuery = { [FILTERED_SEARCH_TERM_KEY]: 'foo' },
    provide = {},
    userPreferencesUpdateHandler = userPreferencesUpdateSuccessHandler,
  } = {}) => {
    mockApollo = createMockApollo([[userPreferencesUpdate, userPreferencesUpdateHandler]]);
    router = createRouter();
    await router.push({ query: routeQuery });

    wrapper = shallowMountExtended(App, {
      apolloProvider: mockApollo,
      router,
      provide: { ...defaultProvide, ...provide },
    });
  };

  const findPageTitle = () => wrapper.findByText('Groups and projects');
  const findFilteredSearchAndSort = () => wrapper.findComponent(FilteredSearchAndSort);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findProjectsView = () => wrapper.findComponent(ProjectsView);
  const findNewGroupButton = () => wrapper.findComponent(NewGroupButton);
  const findNewProjectButton = () => wrapper.findComponent(NewProjectButton);

  afterEach(() => {
    mockApollo = null;
    router = null;
  });

  it('renders page title as Groups and projects', async () => {
    await createComponent();

    expect(findPageTitle().exists()).toBe(true);
  });

  describe.each`
    display                   | expectedComponent | expectedDisplayListboxSelectedProp | expectedRecentSearchesStorageKey
    ${null}                   | ${GroupsView}     | ${RESOURCE_TYPE_GROUPS}            | ${RECENT_SEARCHES_STORAGE_KEY_GROUPS}
    ${'unsupported_value'}    | ${GroupsView}     | ${RESOURCE_TYPE_GROUPS}            | ${RECENT_SEARCHES_STORAGE_KEY_GROUPS}
    ${RESOURCE_TYPE_GROUPS}   | ${GroupsView}     | ${RESOURCE_TYPE_GROUPS}            | ${RECENT_SEARCHES_STORAGE_KEY_GROUPS}
    ${RESOURCE_TYPE_PROJECTS} | ${ProjectsView}   | ${RESOURCE_TYPE_PROJECTS}          | ${RECENT_SEARCHES_STORAGE_KEY_PROJECTS}
  `(
    'when `display` query string is $display',
    ({
      display,
      expectedComponent,
      expectedDisplayListboxSelectedProp,
      expectedRecentSearchesStorageKey,
    }) => {
      beforeEach(async () => {
        await createComponent({
          routeQuery: {
            display,
            [FILTERED_SEARCH_TERM_KEY]: 'foo',
            start_cursor: mockStartCursor,
            end_cursor: mockEndCursor,
          },
        });
      });

      it('renders expected component with correct props', () => {
        expect(wrapper.findComponent(expectedComponent).props()).toMatchObject({
          startCursor: mockStartCursor,
          endCursor: mockEndCursor,
          [FILTERED_SEARCH_TERM_KEY]: 'foo',
          sortName: SORT_ITEM_NAME.value,
          sortDirection: SORT_DIRECTION_ASC,
        });
      });

      it('renders display listbox with correct props', () => {
        expect(findListbox().props()).toMatchObject({
          selected: expectedDisplayListboxSelectedProp,
          items: App.displayListboxItems,
          headerText: App.i18n.displayListboxHeaderText,
        });
      });

      it('renders filtered search bar with correct `filteredSearchRecentSearchesStorageKey` prop', () => {
        expect(findFilteredSearchAndSort().props('filteredSearchRecentSearchesStorageKey')).toBe(
          expectedRecentSearchesStorageKey,
        );
      });
    },
  );

  it('renders filtered search bar with correct props', async () => {
    await createComponent();

    expect(findFilteredSearchAndSort().props()).toMatchObject({
      filteredSearchTokens: [],
      filteredSearchQuery: { [FILTERED_SEARCH_TERM_KEY]: 'foo' },
      filteredSearchTermKey: FILTERED_SEARCH_TERM_KEY,
      filteredSearchNamespace: FILTERED_SEARCH_NAMESPACE,
      filteredSearchRecentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_GROUPS,
      sortOptions: SORT_ITEMS,
      activeSortOption: SORT_ITEM_NAME,
      isAscending: true,
    });
  });

  describe('when `sort_name` query string is not a valid sort option', () => {
    beforeEach(async () => {
      await createComponent({ routeQuery: { sort_name: 'foo-bar' } });
    });

    it('defaults to sorting by name', () => {
      expect(findFilteredSearchAndSort().props('activeSortOption')).toEqual(SORT_ITEM_NAME);
    });
  });

  describe('when `userPreferenceSortName` and `userPreferenceSortDirection` is set', () => {
    beforeEach(async () => {
      await createComponent({
        provide: {
          userPreferenceSortName: SORT_ITEM_CREATED_AT.value,
          userPreferenceSortDirection: SORT_DIRECTION_DESC,
        },
      });
    });

    it('renders filtered search bar with correct sort props', () => {
      expect(findFilteredSearchAndSort().props()).toMatchObject({
        activeSortOption: SORT_ITEM_CREATED_AT,
        isAscending: false,
      });
    });

    it('renders view component with correct sort props', () => {
      expect(wrapper.findComponent(GroupsView).props()).toMatchObject({
        sortName: SORT_ITEM_CREATED_AT.value,
        sortDirection: SORT_DIRECTION_DESC,
      });
    });
  });

  describe('when `userPreferenceDisplay` is set', () => {
    beforeEach(async () => {
      await createComponent({
        provide: {
          userPreferenceDisplay: RESOURCE_TYPE_PROJECTS,
        },
      });
    });

    it('renders display listbox with correct item selected', () => {
      expect(findListbox().props()).toMatchObject({
        selected: RESOURCE_TYPE_PROJECTS,
      });
    });

    it('renders correct view component', () => {
      expect(wrapper.findComponent(ProjectsView).exists()).toBe(true);
    });
  });

  describe('actions', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('renders NewProjectButton', () => {
      expect(findNewProjectButton().exists()).toBe(true);
    });

    it('renders NewGroupButton with correct props', () => {
      expect(findNewGroupButton().props()).toStrictEqual({ category: 'secondary' });
    });
  });

  describe('when filtered search bar is submitted', () => {
    describe('when search term is 3 characters or more', () => {
      const searchTerm = 'foo bar';

      beforeEach(async () => {
        await createComponent();

        findFilteredSearchAndSort().vm.$emit('filter', { [FILTERED_SEARCH_TERM_KEY]: searchTerm });
        await waitForPromises();
      });

      it(`updates \`${FILTERED_SEARCH_TERM_KEY}\` query string`, () => {
        expect(router.currentRoute.query).toEqual({ [FILTERED_SEARCH_TERM_KEY]: searchTerm });
      });
    });

    describe('when search term is less than 3 characters', () => {
      const searchTerm = 'fo';

      beforeEach(async () => {
        await createComponent({ routeQuery: {} });

        findFilteredSearchAndSort().vm.$emit('filter', { [FILTERED_SEARCH_TERM_KEY]: searchTerm });
      });

      it('does not update query string', () => {
        expect(router.currentRoute.query).toEqual({});
      });
    });

    describe('when search term is empty but there are other filters', () => {
      beforeEach(async () => {
        await createComponent();

        findFilteredSearchAndSort().vm.$emit('filter', { foo: 'bar' });
        await waitForPromises();
      });

      it('updates query string', () => {
        expect(router.currentRoute.query).toEqual({ foo: 'bar' });
      });
    });
  });

  describe('when display listbox is changed', () => {
    beforeEach(async () => {
      await createComponent();

      findListbox().vm.$emit('select', RESOURCE_TYPE_PROJECTS);
      await waitForPromises();
    });

    it('updates `display` query string', () => {
      expect(router.currentRoute.query.display).toBe(RESOURCE_TYPE_PROJECTS);
    });

    it('calls `userPreferencesUpdate` mutation with correct variables', () => {
      expect(userPreferencesUpdateSuccessHandler).toHaveBeenCalledWith({
        input: { organizationGroupsProjectsDisplay: 'PROJECTS' },
      });
    });
  });

  describe('when sort item is changed', () => {
    beforeEach(async () => {
      await createComponent({
        routeQuery: {
          display: RESOURCE_TYPE_PROJECTS,
          start_cursor: mockStartCursor,
          end_cursor: mockEndCursor,
          [FILTERED_SEARCH_TERM_KEY]: 'foo',
        },
      });

      findFilteredSearchAndSort().vm.$emit('sort-by-change', SORT_ITEM_CREATED_AT.value);
      await waitForPromises();
    });

    it('updates `sort_name` query string', () => {
      expect(router.currentRoute.query).toMatchObject({
        display: RESOURCE_TYPE_PROJECTS,
        sort_name: SORT_ITEM_CREATED_AT.value,
        [FILTERED_SEARCH_TERM_KEY]: 'foo',
      });
    });

    it('calls `userPreferencesUpdate` mutation with correct variables', () => {
      expect(userPreferencesUpdateSuccessHandler).toHaveBeenCalledWith({
        input: { organizationGroupsProjectsSort: 'CREATED_ASC' },
      });
    });
  });

  describe('when sort direction is changed', () => {
    beforeEach(async () => {
      await createComponent({
        routeQuery: {
          display: RESOURCE_TYPE_PROJECTS,
          start_cursor: mockStartCursor,
          end_cursor: mockEndCursor,
          [FILTERED_SEARCH_TERM_KEY]: 'foo',
        },
      });

      findFilteredSearchAndSort().vm.$emit('sort-direction-change', false);
      await waitForPromises();
    });

    it('updates `sort_direction` query string', () => {
      expect(router.currentRoute.query).toMatchObject({
        display: RESOURCE_TYPE_PROJECTS,
        sort_direction: SORT_DIRECTION_DESC,
        [FILTERED_SEARCH_TERM_KEY]: 'foo',
      });
    });

    it('calls `userPreferencesUpdate` mutation with correct variables', () => {
      expect(userPreferencesUpdateSuccessHandler).toHaveBeenCalledWith({
        input: { organizationGroupsProjectsSort: 'NAME_DESC' },
      });
    });
  });

  describe('when `userPreferencesUpdate` mutation fails', () => {
    const error = new Error();
    const errorHandler = jest.fn().mockRejectedValue(error);

    beforeEach(async () => {
      await createComponent({ userPreferencesUpdateHandler: errorHandler });

      findListbox().vm.$emit('select', RESOURCE_TYPE_PROJECTS);
      await waitForPromises();
    });

    it('captures error in Sentry', () => {
      expect(Sentry.captureException).toHaveBeenCalledWith(error);
    });
  });

  describe(`when \`${FILTERED_SEARCH_TERM_KEY}\` query string is not set`, () => {
    beforeEach(async () => {
      await createComponent({ routeQuery: {} });
    });

    it('passes empty search query to `FilteredSearchAndSort`', () => {
      expect(findFilteredSearchAndSort().props('filteredSearchQuery')).toEqual({});
    });
  });

  describe('when page is changed', () => {
    describe('when going to next page', () => {
      beforeEach(async () => {
        await createComponent({ routeQuery: { display: RESOURCE_TYPE_PROJECTS } });
        findProjectsView().vm.$emit('page-change', {
          endCursor: mockEndCursor,
          startCursor: null,
          hasPreviousPage: true,
        });
        await waitForPromises();
      });

      it('sets `end_cursor` query string', () => {
        expect(router.currentRoute.query).toMatchObject({
          display: RESOURCE_TYPE_PROJECTS,
          end_cursor: mockEndCursor,
        });
      });
    });

    describe('when going to previous page', () => {
      it('sets `start_cursor` query string', async () => {
        await createComponent({
          routeQuery: {
            display: RESOURCE_TYPE_PROJECTS,
            start_cursor: mockStartCursor,
            end_cursor: mockEndCursor,
          },
        });

        findProjectsView().vm.$emit('page-change', {
          endCursor: null,
          startCursor: mockStartCursor,
          hasPreviousPage: true,
        });

        expect(router.currentRoute.query).toMatchObject({
          display: RESOURCE_TYPE_PROJECTS,
          start_cursor: mockStartCursor,
        });
      });
    });
  });
});
