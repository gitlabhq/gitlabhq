import { GlSorting } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import FilteredSearchBarRoot from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { RECENT_SEARCHES_STORAGE_KEY_GROUPS } from '~/filtered_search/recent_searches_storage_keys';
import {
  SORT_ITEMS,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
} from '~/organizations/groups_and_projects/constants';
import { SORT_ITEM_NAME } from '~/organizations/shared/constants';
import {
  FILTERED_SEARCH_TERM,
  TOKEN_EMPTY_SEARCH_TERM,
} from '~/vue_shared/components/filtered_search_bar/constants';

describe('FilteredSearchAndSort', () => {
  let wrapper;

  const defaultPropsData = {
    activeSortOption: SORT_ITEM_NAME,
    filteredSearchNamespace: FILTERED_SEARCH_NAMESPACE,
    filteredSearchQuery: {},
    filteredSearchRecentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_GROUPS,
    filteredSearchTermKey: FILTERED_SEARCH_TERM_KEY,
    filteredSearchTokens: [],
    isAscending: true,
    sortOptions: SORT_ITEMS,
  };

  const createComponent = ({ propsData = {}, scopedSlots = {} } = {}) => {
    wrapper = shallowMountExtended(FilteredSearchAndSort, {
      propsData: { ...defaultPropsData, ...propsData },
      scopedSlots,
    });
  };

  const findFilteredSearchAndSortRoot = () => wrapper.findComponent(FilteredSearchBarRoot);
  const findGlSorting = () => wrapper.findComponent(GlSorting);

  it('renders `FilteredSearchBarRoot` and passes correct props', () => {
    createComponent();

    expect(findFilteredSearchAndSortRoot().props()).toMatchObject({
      namespace: defaultPropsData.filteredSearchNamespace,
      tokens: defaultPropsData.filteredSearchTokens,
      initialFilterValue: [TOKEN_EMPTY_SEARCH_TERM],
      syncFilterAndSort: true,
      recentSearchesStorageKey: defaultPropsData.filteredSearchRecentSearchesStorageKey,
      searchInputPlaceholder: 'Search or filter results…',
    });
  });

  it('renders `GlSorting` and passes correct props', () => {
    createComponent();

    expect(findGlSorting().props()).toMatchObject({
      dropdownClass: 'gl-w-full',
      block: true,
      text: defaultPropsData.activeSortOption.text,
      isAscending: defaultPropsData.isAscending,
      sortOptions: defaultPropsData.sortOptions,
      sortBy: defaultPropsData.activeSortOption.value,
    });
  });

  it('renders default slot', () => {
    createComponent({ scopedSlots: { default: '<div data-testid="default-slot"></div>' } });

    expect(wrapper.findByTestId('default-slot').exists()).toBe(true);
  });

  describe('when `FilteredSearchBarRoot` emits `onFilter` event', () => {
    beforeEach(() => {
      createComponent();

      findFilteredSearchAndSortRoot().vm.$emit('onFilter', [
        { type: FILTERED_SEARCH_TERM, value: { data: 'foo bar' } },
      ]);
    });

    it('emits `filter` event with payload transformed to a query object', () => {
      expect(wrapper.emitted('filter')).toEqual([[{ [FILTERED_SEARCH_TERM_KEY]: 'foo bar' }]]);
    });
  });

  describe('when `GlSorting` emits `sortDirectionChange` event', () => {
    beforeEach(() => {
      createComponent();

      findGlSorting().vm.$emit('sortDirectionChange', true);
    });

    it('emits `sort-direction-change` event', () => {
      expect(wrapper.emitted('sort-direction-change')).toEqual([[true]]);
    });
  });

  describe('when `GlSorting` emits `sortByChange` event', () => {
    beforeEach(() => {
      createComponent();

      findGlSorting().vm.$emit('sortByChange', defaultPropsData.sortOptions[1].value);
    });

    it('emits `sort-by-change` event', () => {
      expect(wrapper.emitted('sort-by-change')).toEqual([[defaultPropsData.sortOptions[1].value]]);
    });
  });

  describe('when `sortOptions` prop is not passed', () => {
    beforeEach(() => {
      createComponent({ propsData: { sortOptions: undefined } });
    });

    it('does not show sort dropdown', () => {
      expect(findGlSorting().exists()).toBe(false);
    });
  });
});
