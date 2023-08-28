import { GlCollapsibleListbox, GlSorting, GlSortingItem } from '@gitlab/ui';
import App from '~/organizations/groups_and_projects/components/app.vue';
import GroupsPage from '~/organizations/groups_and_projects/components/groups_page.vue';
import ProjectsPage from '~/organizations/groups_and_projects/components/projects_page.vue';
import { RESOURCE_TYPE_GROUPS, RESOURCE_TYPE_PROJECTS } from '~/organizations/constants';
import {
  SORT_ITEM_CREATED,
  SORT_DIRECTION_DESC,
} from '~/organizations/groups_and_projects/constants';
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

  describe.each`
    display                   | expectedComponent | expectedDisplayListboxSelectedProp
    ${null}                   | ${GroupsPage}     | ${RESOURCE_TYPE_GROUPS}
    ${'unsupported_value'}    | ${GroupsPage}     | ${RESOURCE_TYPE_GROUPS}
    ${RESOURCE_TYPE_GROUPS}   | ${GroupsPage}     | ${RESOURCE_TYPE_GROUPS}
    ${RESOURCE_TYPE_PROJECTS} | ${ProjectsPage}   | ${RESOURCE_TYPE_PROJECTS}
  `(
    'when `display` query string is $display',
    ({ display, expectedComponent, expectedDisplayListboxSelectedProp }) => {
      beforeEach(() => {
        createComponent({ routeQuery: { display } });
      });

      it('renders expected component', () => {
        expect(wrapper.findComponent(expectedComponent).exists()).toBe(true);
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

    const sortItems = wrapper.findAllComponents(GlSortingItem).wrappers.map((sortItemWrapper) => ({
      active: sortItemWrapper.attributes('active'),
      text: sortItemWrapper.text(),
    }));

    expect(findSort().props()).toMatchObject({
      isAscending: true,
      text: SORT_ITEM_CREATED.text,
    });
    expect(sortItems).toEqual([
      {
        active: 'true',
        text: SORT_ITEM_CREATED.text,
      },
    ]);
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
      createComponent();

      wrapper.findComponent(GlSortingItem).trigger('click', SORT_ITEM_CREATED);
    });

    it('updates `sort_name` query string', () => {
      expect(routerMock.push).toHaveBeenCalledWith({
        query: { sort_name: SORT_ITEM_CREATED.name, search: 'foo' },
      });
    });
  });

  describe('when sort direction is changed', () => {
    beforeEach(() => {
      createComponent();

      findSort().vm.$emit('sortDirectionChange', false);
    });

    it('updates `sort_direction` query string', () => {
      expect(routerMock.push).toHaveBeenCalledWith({
        query: { sort_direction: SORT_DIRECTION_DESC, search: 'foo' },
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
});
