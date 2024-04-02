import { GlCollapsibleListbox } from '@gitlab/ui';
import App from '~/organizations/groups_and_projects/components/app.vue';
import GroupsView from '~/organizations/shared/components/groups_view.vue';
import ProjectsView from '~/organizations/shared/components/projects_view.vue';
import NewGroupButton from '~/organizations/shared/components/new_group_button.vue';
import NewProjectButton from '~/organizations/shared/components/new_project_button.vue';
import { RESOURCE_TYPE_GROUPS, RESOURCE_TYPE_PROJECTS } from '~/organizations/constants';
import {
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
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('GroupsAndProjectsApp', () => {
  const router = createRouter();
  const routerMock = {
    push: jest.fn(),
  };
  const mockEndCursor = 'mockEndCursor';
  const mockStartCursor = 'mockStartCursor';

  let wrapper;

  const createComponent = ({ routeQuery = { [FILTERED_SEARCH_TERM_KEY]: 'foo' } } = {}) => {
    wrapper = shallowMountExtended(App, {
      router,
      mocks: { $route: { path: '/', query: routeQuery }, $router: routerMock },
    });
  };

  const findPageTitle = () => wrapper.findByText('Groups and projects');
  const findFilteredSearchAndSort = () => wrapper.findComponent(FilteredSearchAndSort);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findProjectsView = () => wrapper.findComponent(ProjectsView);
  const findNewGroupButton = () => wrapper.findComponent(NewGroupButton);
  const findNewProjectButton = () => wrapper.findComponent(NewProjectButton);

  it('renders page title as Groups and projects', () => {
    createComponent();

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
      beforeEach(() => {
        createComponent({
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

  it('renders filtered search bar with correct props', () => {
    createComponent();

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
    beforeEach(() => {
      createComponent({ routeQuery: { sort_name: 'foo-bar' } });
    });

    it('defaults to sorting by name', () => {
      expect(findFilteredSearchAndSort().props('activeSortOption')).toEqual(SORT_ITEM_NAME);
    });
  });

  describe('actions', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders NewProjectButton', () => {
      expect(findNewProjectButton().exists()).toBe(true);
    });

    it('renders NewGroupButton with correct props', () => {
      expect(findNewGroupButton().props()).toStrictEqual({ category: 'secondary' });
    });
  });

  describe('when filtered search bar is submitted', () => {
    const searchTerm = 'foo bar';

    beforeEach(() => {
      createComponent();

      findFilteredSearchAndSort().vm.$emit('filter', { [FILTERED_SEARCH_TERM_KEY]: searchTerm });
    });

    it(`updates \`${FILTERED_SEARCH_TERM_KEY}\` query string`, () => {
      expect(routerMock.push).toHaveBeenCalledWith({
        query: { [FILTERED_SEARCH_TERM_KEY]: searchTerm },
      });
    });
  });

  describe('when display listbox is changed', () => {
    beforeEach(() => {
      createComponent();

      findListbox().vm.$emit('select', RESOURCE_TYPE_PROJECTS);
    });

    it('updates `display` query string', () => {
      expect(routerMock.push).toHaveBeenCalledWith({ query: { display: RESOURCE_TYPE_PROJECTS } });
    });
  });

  describe('when sort item is changed', () => {
    beforeEach(() => {
      createComponent({
        routeQuery: {
          display: RESOURCE_TYPE_PROJECTS,
          start_cursor: mockStartCursor,
          end_cursor: mockEndCursor,
          [FILTERED_SEARCH_TERM_KEY]: 'foo',
        },
      });

      findFilteredSearchAndSort().vm.$emit('sort-by-change', SORT_ITEM_CREATED_AT.value);
    });

    it('updates `sort_name` query string', () => {
      expect(routerMock.push).toHaveBeenCalledWith({
        query: {
          display: RESOURCE_TYPE_PROJECTS,
          sort_name: SORT_ITEM_CREATED_AT.value,
          [FILTERED_SEARCH_TERM_KEY]: 'foo',
        },
      });
    });
  });

  describe('when sort direction is changed', () => {
    beforeEach(() => {
      createComponent({
        routeQuery: {
          display: RESOURCE_TYPE_PROJECTS,
          start_cursor: mockStartCursor,
          end_cursor: mockEndCursor,
          [FILTERED_SEARCH_TERM_KEY]: 'foo',
        },
      });

      findFilteredSearchAndSort().vm.$emit('sort-direction-change', false);
    });

    it('updates `sort_direction` query string', () => {
      expect(routerMock.push).toHaveBeenCalledWith({
        query: {
          display: RESOURCE_TYPE_PROJECTS,
          sort_direction: SORT_DIRECTION_DESC,
          [FILTERED_SEARCH_TERM_KEY]: 'foo',
        },
      });
    });
  });

  describe(`when \`${FILTERED_SEARCH_TERM_KEY}\` query string is not set`, () => {
    beforeEach(() => {
      createComponent({ routeQuery: {} });
    });

    it('passes empty search query to `FilteredSearchAndSort`', () => {
      expect(findFilteredSearchAndSort().props('filteredSearchQuery')).toEqual({});
    });
  });

  describe('when page is changed', () => {
    describe('when going to next page', () => {
      beforeEach(() => {
        createComponent({ routeQuery: { display: RESOURCE_TYPE_PROJECTS } });
        findProjectsView().vm.$emit('page-change', {
          endCursor: mockEndCursor,
          startCursor: null,
          hasPreviousPage: true,
        });
      });

      it('sets `end_cursor` query string', () => {
        expect(routerMock.push).toHaveBeenCalledWith({
          query: { display: RESOURCE_TYPE_PROJECTS, end_cursor: mockEndCursor },
        });
      });
    });

    describe('when going to previous page', () => {
      it('sets `start_cursor` query string', () => {
        createComponent({
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

        expect(routerMock.push).toHaveBeenCalledWith({
          query: { display: RESOURCE_TYPE_PROJECTS, start_cursor: mockStartCursor },
        });
      });
    });
  });
});
