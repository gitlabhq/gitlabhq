import GroupsListWithFilteredSearchApp from '~/groups/components/groups_list_with_filtered_search_app.vue';
import { createRouter } from '~/groups/init_groups_list_with_filtered_search';
import {
  SORTING_ITEM_CREATED,
  SORTING_ITEM_UPDATED,
  GROUPS_LIST_SORTING_ITEMS,
  GROUPS_LIST_FILTERED_SEARCH_TERM_KEY,
  EXPLORE_FILTERED_SEARCH_NAMESPACE,
} from '~/groups/constants';
import { RECENT_SEARCHES_STORAGE_KEY_GROUPS } from '~/filtered_search/recent_searches_storage_keys';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import GroupsApp from '~/groups/components/app.vue';
import GroupsService from '~/groups/service/groups_service';
import GroupsStore from '~/groups/store/groups_store';
import eventHub from '~/groups/event_hub';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('GroupsListWithFilteredSearch', () => {
  const router = createRouter();
  const routerMock = {
    push: jest.fn(),
  };

  let wrapper;

  const defaultPropsData = {
    filteredSearchNamespace: EXPLORE_FILTERED_SEARCH_NAMESPACE,
    endpoint: '/explore/groups.json',
    initialSort: SORTING_ITEM_UPDATED.asc,
  };

  const createComponent = ({
    routeQuery = { [GROUPS_LIST_FILTERED_SEARCH_TERM_KEY]: 'foo' },
  } = {}) => {
    wrapper = shallowMountExtended(GroupsListWithFilteredSearchApp, {
      router,
      mocks: { $route: { path: '/', query: routeQuery }, $router: routerMock },
      propsData: defaultPropsData,
    });
  };

  const findFilteredSearchAndSort = () => wrapper.findComponent(FilteredSearchAndSort);

  it('renders filtered search bar with correct props', () => {
    createComponent();

    expect(findFilteredSearchAndSort().props()).toMatchObject({
      filteredSearchTokens: [],
      filteredSearchQuery: { [GROUPS_LIST_FILTERED_SEARCH_TERM_KEY]: 'foo' },
      filteredSearchTermKey: GROUPS_LIST_FILTERED_SEARCH_TERM_KEY,
      filteredSearchNamespace: EXPLORE_FILTERED_SEARCH_NAMESPACE,
      filteredSearchRecentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_GROUPS,
      sortOptions: GROUPS_LIST_SORTING_ITEMS.map((sortItem) => ({
        value: sortItem.asc,
        text: sortItem.label,
      })),
      activeSortOption: {
        value: SORTING_ITEM_UPDATED.asc,
        text: SORTING_ITEM_UPDATED.label,
      },
      isAscending: true,
    });
  });

  it('renders `GroupsApp`', () => {
    createComponent();

    const service = new GroupsService(defaultPropsData.endpoint);
    const store = new GroupsStore({ hideProjects: true });

    expect(wrapper.findComponent(GroupsApp).props()).toMatchObject({
      service,
      store,
    });
  });

  describe('when filtered search bar is submitted', () => {
    const searchTerm = 'foo bar';

    beforeEach(() => {
      jest.spyOn(eventHub, '$emit');
      createComponent();

      findFilteredSearchAndSort().vm.$emit('filter', {
        [GROUPS_LIST_FILTERED_SEARCH_TERM_KEY]: searchTerm,
      });
    });

    it(`updates \`${GROUPS_LIST_FILTERED_SEARCH_TERM_KEY}\` query string`, () => {
      expect(routerMock.push).toHaveBeenCalledWith({
        query: { [GROUPS_LIST_FILTERED_SEARCH_TERM_KEY]: searchTerm },
      });
    });

    it('emits `fetchFilteredAndSortedGroups` with correct arguments', () => {
      expect(eventHub.$emit).toHaveBeenCalledWith('fetchFilteredAndSortedGroups', {
        filterGroupsBy: searchTerm,
        sortBy: defaultPropsData.initialSort,
      });
    });
  });

  describe('when filtered search bar is cleared', () => {
    beforeEach(() => {
      createComponent();

      findFilteredSearchAndSort().vm.$emit('filter', {
        [GROUPS_LIST_FILTERED_SEARCH_TERM_KEY]: '',
      });
    });

    it(`removes \`${GROUPS_LIST_FILTERED_SEARCH_TERM_KEY}\` query string`, () => {
      expect(routerMock.push).toHaveBeenCalledWith({
        query: {},
      });
    });
  });

  describe('when sort item is changed', () => {
    beforeEach(() => {
      createComponent({
        routeQuery: {
          [GROUPS_LIST_FILTERED_SEARCH_TERM_KEY]: 'foo',
        },
      });

      findFilteredSearchAndSort().vm.$emit('sort-by-change', SORTING_ITEM_CREATED.asc);
    });

    it('updates `sort` query string', () => {
      expect(routerMock.push).toHaveBeenCalledWith({
        query: {
          sort: SORTING_ITEM_CREATED.asc,
          [GROUPS_LIST_FILTERED_SEARCH_TERM_KEY]: 'foo',
        },
      });
    });
  });

  describe('when sort direction is changed', () => {
    beforeEach(() => {
      createComponent({
        routeQuery: {
          [GROUPS_LIST_FILTERED_SEARCH_TERM_KEY]: 'foo',
        },
      });

      findFilteredSearchAndSort().vm.$emit('sort-direction-change', false);
    });

    it('updates `sort` query string', () => {
      expect(routerMock.push).toHaveBeenCalledWith({
        query: {
          sort: SORTING_ITEM_UPDATED.desc,
          [GROUPS_LIST_FILTERED_SEARCH_TERM_KEY]: 'foo',
        },
      });
    });
  });
});
