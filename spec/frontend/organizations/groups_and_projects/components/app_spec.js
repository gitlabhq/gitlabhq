import { GlCollapsibleListbox, GlSorting } from '@gitlab/ui';
import App from '~/organizations/groups_and_projects/components/app.vue';
import GroupsView from '~/organizations/shared/components/groups_view.vue';
import ProjectsView from '~/organizations/shared/components/projects_view.vue';
import { RESOURCE_TYPE_GROUPS, RESOURCE_TYPE_PROJECTS } from '~/organizations/constants';
import { SORT_ITEMS } from '~/organizations/groups_and_projects/constants';
import {
  SORT_ITEM_NAME,
  SORT_ITEM_CREATED_AT,
  SORT_DIRECTION_DESC,
  SORT_DIRECTION_ASC,
} from '~/organizations/shared/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import {
  FILTERED_SEARCH_TERM,
  TOKEN_EMPTY_SEARCH_TERM,
} from '~/vue_shared/components/filtered_search_bar/constants';
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

  const createComponent = ({ routeQuery = { search: 'foo' } } = {}) => {
    wrapper = shallowMountExtended(App, {
      router,
      mocks: { $route: { path: '/', query: routeQuery }, $router: routerMock },
    });
  };

  const findFilteredSearchBar = () => wrapper.findComponent(FilteredSearchBar);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSort = () => wrapper.findComponent(GlSorting);
  const findProjectsView = () => wrapper.findComponent(ProjectsView);

  describe.each`
    display                   | expectedComponent | expectedDisplayListboxSelectedProp
    ${null}                   | ${GroupsView}     | ${RESOURCE_TYPE_GROUPS}
    ${'unsupported_value'}    | ${GroupsView}     | ${RESOURCE_TYPE_GROUPS}
    ${RESOURCE_TYPE_GROUPS}   | ${GroupsView}     | ${RESOURCE_TYPE_GROUPS}
    ${RESOURCE_TYPE_PROJECTS} | ${ProjectsView}   | ${RESOURCE_TYPE_PROJECTS}
  `(
    'when `display` query string is $display',
    ({ display, expectedComponent, expectedDisplayListboxSelectedProp }) => {
      beforeEach(() => {
        createComponent({
          routeQuery: {
            display,
            search: 'foo',
            start_cursor: mockStartCursor,
            end_cursor: mockEndCursor,
          },
        });
      });

      it('renders expected component with correct props', () => {
        expect(wrapper.findComponent(expectedComponent).props()).toMatchObject({
          startCursor: mockStartCursor,
          endCursor: mockEndCursor,
          search: 'foo',
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
    },
  );

  it('renders filtered search bar with correct props', () => {
    createComponent();

    expect(findFilteredSearchBar().props()).toMatchObject({
      namespace: App.filteredSearch.namespace,
      tokens: App.filteredSearch.tokens,
      initialFilterValue: [
        {
          type: FILTERED_SEARCH_TERM,
          value: {
            data: 'foo',
            operator: undefined,
          },
        },
      ],
      syncFilterAndSort: true,
      recentSearchesStorageKey: App.filteredSearch.recentSearchesStorageKey,
      searchInputPlaceholder: App.i18n.searchInputPlaceholder,
    });
  });

  it('renders sort dropdown with sort items and correct props', () => {
    createComponent();

    expect(findSort().props()).toMatchObject({
      isAscending: true,
      text: 'Name',
      sortBy: SORT_ITEM_NAME.value,
      sortOptions: SORT_ITEMS,
    });
  });

  describe('when filtered search bar is submitted', () => {
    const searchTerm = 'foo bar';

    beforeEach(() => {
      createComponent();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { id: 'token-0', type: FILTERED_SEARCH_TERM, value: { data: searchTerm } },
      ]);
    });

    it('updates `search` query string', () => {
      expect(routerMock.push).toHaveBeenCalledWith({ query: { search: searchTerm } });
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
          search: 'foo',
        },
      });

      findSort().vm.$emit('sortByChange', SORT_ITEM_CREATED_AT.value);
    });

    it('updates `sort_name` query string', () => {
      expect(routerMock.push).toHaveBeenCalledWith({
        query: {
          display: RESOURCE_TYPE_PROJECTS,
          sort_name: SORT_ITEM_CREATED_AT.value,
          search: 'foo',
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
          search: 'foo',
        },
      });

      findSort().vm.$emit('sortDirectionChange', false);
    });

    it('updates `sort_direction` query string', () => {
      expect(routerMock.push).toHaveBeenCalledWith({
        query: {
          display: RESOURCE_TYPE_PROJECTS,
          sort_direction: SORT_DIRECTION_DESC,
          search: 'foo',
        },
      });
    });
  });

  describe('when `search` query string is not set', () => {
    beforeEach(() => {
      createComponent({ routeQuery: {} });
    });

    it('passes empty search term token to filtered search', () => {
      expect(findFilteredSearchBar().props('initialFilterValue')).toEqual([
        TOKEN_EMPTY_SEARCH_TERM,
      ]);
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
