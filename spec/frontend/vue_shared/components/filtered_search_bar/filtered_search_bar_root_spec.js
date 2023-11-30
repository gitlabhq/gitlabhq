import { GlDropdownItem, GlSorting, GlFilteredSearch, GlFormCheckbox } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';

import { nextTick } from 'vue';
import RecentSearchesService from '~/filtered_search/services/recent_searches_service';
import RecentSearchesStore from '~/filtered_search/stores/recent_searches_store';
import {
  FILTERED_SEARCH_TERM,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBarRoot from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { uniqueTokens } from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';

import {
  mockAvailableTokens,
  mockMembershipToken,
  mockMembershipTokenOptionsWithoutTitles,
  mockSortOptions,
  mockHistoryItems,
  tokenValueAuthor,
  tokenValueLabel,
  tokenValueMilestone,
  tokenValueMembership,
  tokenValueConfidential,
} from './mock_data';

jest.mock('~/vue_shared/components/filtered_search_bar/filtered_search_utils', () => ({
  uniqueTokens: jest.fn().mockImplementation((tokens) => tokens),
  stripQuotes: jest.requireActual('~/lib/utils/text_utility').stripQuotes,
  filterEmptySearchTerm: jest.requireActual(
    '~/vue_shared/components/filtered_search_bar/filtered_search_utils',
  ).filterEmptySearchTerm,
}));

const createComponent = ({
  shallow = true,
  namespace = 'gitlab-org/gitlab-test',
  recentSearchesStorageKey = 'requirements',
  tokens = mockAvailableTokens,
  sortOptions,
  initialSortBy,
  initialFilterValue = [],
  showCheckbox = false,
  checkboxChecked = false,
  searchInputPlaceholder = 'Filter requirements',
} = {}) => {
  const mountMethod = shallow ? shallowMount : mount;

  return mountMethod(FilteredSearchBarRoot, {
    propsData: {
      namespace,
      recentSearchesStorageKey,
      tokens,
      sortOptions,
      initialSortBy,
      initialFilterValue,
      showCheckbox,
      checkboxChecked,
      searchInputPlaceholder,
    },
  });
};

describe('FilteredSearchBarRoot', () => {
  let wrapper;

  const findGlSorting = () => wrapper.findComponent(GlSorting);
  const findGlFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);

  describe('data', () => {
    describe('when `sortOptions` are provided', () => {
      beforeEach(() => {
        wrapper = createComponent({ sortOptions: mockSortOptions });
      });

      it('sets a correct initial value for GlFilteredSearch', () => {
        expect(findGlFilteredSearch().props('value')).toEqual([]);
      });

      it('emits an event with the selectedSortOption provided by default', async () => {
        findGlSorting().vm.$emit('sortByChange', mockSortOptions[1].id);
        await nextTick();

        expect(wrapper.emitted('onSort')[0]).toEqual([mockSortOptions[1].sortDirection.descending]);
      });

      it('emits an event with the selectedSortDirection provided by default', async () => {
        findGlSorting().vm.$emit('sortDirectionChange', true);
        await nextTick();

        expect(wrapper.emitted('onSort')[0]).toEqual([mockSortOptions[0].sortDirection.ascending]);
      });
    });

    it('does not initialize the sort dropdown when `sortOptions` are not provided', () => {
      wrapper = createComponent();

      expect(findGlSorting().exists()).toBe(false);
    });
  });

  describe('computed', () => {
    describe('tokenSymbols', () => {
      it('returns a map containing type and symbols from `tokens` prop', () => {
        expect(wrapper.vm.tokenSymbols).toEqual({
          [TOKEN_TYPE_AUTHOR]: '@',
          [TOKEN_TYPE_LABEL]: '~',
          [TOKEN_TYPE_MILESTONE]: '%',
        });
      });
    });

    describe('tokenTitles', () => {
      it('returns a map containing type and title from `tokens` prop', () => {
        expect(wrapper.vm.tokenTitles).toEqual({
          [TOKEN_TYPE_AUTHOR]: 'Author',
          [TOKEN_TYPE_LABEL]: 'Label',
          [TOKEN_TYPE_MILESTONE]: 'Milestone',
        });
      });
    });

    describe('sortDirectionIcon', () => {
      beforeEach(() => {
        wrapper = createComponent({ sortOptions: mockSortOptions });
      });

      it('passes isAscending=false to GlSorting by default', () => {
        expect(findGlSorting().props('isAscending')).toBe(false);
      });

      it('renders `sort-lowest` ascending icon when the sort button is clicked', async () => {
        findGlSorting().vm.$emit('sortDirectionChange', true);
        await nextTick();

        expect(findGlSorting().props('isAscending')).toBe(true);
      });
    });

    describe('filteredRecentSearches', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('returns array of recent searches filtering out any string type (unsupported) items', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          recentSearches: [{ foo: 'bar' }, 'foo'],
        });

        await nextTick();

        expect(wrapper.vm.filteredRecentSearches).toHaveLength(1);
        expect(wrapper.vm.filteredRecentSearches[0]).toEqual({ foo: 'bar' });
      });

      it('returns array of recent searches sanitizing any duplicate token values', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          recentSearches: [
            [tokenValueAuthor, tokenValueLabel, tokenValueMilestone, tokenValueLabel],
            [tokenValueAuthor, tokenValueMilestone],
          ],
        });

        await nextTick();

        expect(wrapper.vm.filteredRecentSearches).toHaveLength(2);
        expect(uniqueTokens).toHaveBeenCalled();
      });

      it('returns undefined when recentSearchesStorageKey prop is not set on component', async () => {
        wrapper.setProps({
          recentSearchesStorageKey: '',
        });

        await nextTick();

        expect(wrapper.vm.filteredRecentSearches).not.toBeDefined();
      });
    });
  });

  describe('events', () => {
    it('emits component event `onFilter` with empty array and true when initially selected filter value was cleared', async () => {
      wrapper = createComponent({ initialFilterValue: [tokenValueLabel] });

      wrapper.findComponent(GlFilteredSearch).vm.$emit('clear');

      await nextTick();
      expect(wrapper.emitted('onFilter')[0]).toEqual([[], true]);
    });
  });

  describe('methods', () => {
    describe('setupRecentSearch', () => {
      it('initializes `recentSearchesService` and `recentSearchesStore` props when `recentSearchesStorageKey` is available', () => {
        expect(wrapper.vm.recentSearchesService instanceof RecentSearchesService).toBe(true);
        expect(wrapper.vm.recentSearchesStore instanceof RecentSearchesStore).toBe(true);
      });

      it('initializes `recentSearchesPromise` prop with a promise by using `recentSearchesService.fetch()`', () => {
        jest.spyOn(wrapper.vm.recentSearchesService, 'fetch').mockResolvedValue([]);

        wrapper.vm.setupRecentSearch();

        expect(wrapper.vm.recentSearchesPromise instanceof Promise).toBe(true);
      });
    });

    describe('removeQuotesEnclosure', () => {
      const mockFilters = [tokenValueAuthor, tokenValueLabel, tokenValueConfidential, 'foo'];

      it('returns filter array with unescaped strings for values which have spaces', () => {
        expect(wrapper.vm.removeQuotesEnclosure(mockFilters)).toEqual([
          tokenValueAuthor,
          tokenValueLabel,
          tokenValueConfidential,
          'foo',
        ]);
      });
    });

    describe('handleSortOptionChange', () => {
      it('emits component event `onSort` with selected sort by value', async () => {
        wrapper = createComponent({ sortOptions: mockSortOptions });

        findGlSorting().vm.$emit('sortByChange', mockSortOptions[1].id);
        await nextTick();

        expect(wrapper.vm.selectedSortOption).toBe(mockSortOptions[1]);
        expect(wrapper.emitted('onSort')[0]).toEqual([mockSortOptions[1].sortDirection.descending]);
      });
    });

    describe('handleSortDirectionChange', () => {
      beforeEach(() => {
        wrapper = createComponent({
          sortOptions: mockSortOptions,
          initialSortBy: mockSortOptions[0].sortDirection.descending,
        });
      });

      it('sets sort direction to be opposite of its current value', async () => {
        expect(findGlSorting().props('isAscending')).toBe(false);

        findGlSorting().vm.$emit('sortDirectionChange', true);
        await nextTick();

        expect(findGlSorting().props('isAscending')).toBe(true);
      });

      it('emits component event `onSort` with opposite of currently selected sort by value', () => {
        findGlSorting().vm.$emit('sortDirectionChange', true);

        expect(wrapper.emitted('onSort')[0]).toEqual([mockSortOptions[0].sortDirection.ascending]);
      });
    });

    describe('handleHistoryItemSelected', () => {
      it('emits `onFilter` event with provided filters param', () => {
        jest.spyOn(wrapper.vm, 'removeQuotesEnclosure');

        wrapper.vm.handleHistoryItemSelected(mockHistoryItems[0]);

        expect(wrapper.emitted('onFilter')[0]).toEqual([mockHistoryItems[0]]);
        expect(wrapper.vm.removeQuotesEnclosure).toHaveBeenCalledWith(mockHistoryItems[0]);
      });
    });

    describe('handleClearHistory', () => {
      it('clears search history from recent searches store', () => {
        jest.spyOn(wrapper.vm.recentSearchesStore, 'setRecentSearches').mockReturnValue([]);
        jest.spyOn(wrapper.vm.recentSearchesService, 'save');

        wrapper.vm.handleClearHistory();

        expect(wrapper.vm.recentSearchesStore.setRecentSearches).toHaveBeenCalledWith([]);
        expect(wrapper.vm.recentSearchesService.save).toHaveBeenCalledWith([]);
        expect(wrapper.vm.recentSearches).toEqual([]);
      });
    });

    describe('handleFilterSubmit', () => {
      const mockFilters = [tokenValueAuthor, 'foo'];

      beforeEach(async () => {
        wrapper = createComponent();

        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          filterValue: mockFilters,
        });

        await nextTick();
      });

      it('calls `uniqueTokens` on `filterValue` prop to remove duplicates', async () => {
        findGlFilteredSearch().vm.$emit('submit');
        await nextTick();

        expect(uniqueTokens).toHaveBeenCalledWith(wrapper.vm.filterValue);
      });

      it('calls `recentSearchesStore.addRecentSearch` with serialized value of provided `filters` param', async () => {
        jest.spyOn(wrapper.vm.recentSearchesStore, 'addRecentSearch');

        findGlFilteredSearch().vm.$emit('submit');
        await nextTick();

        return wrapper.vm.recentSearchesPromise.then(() => {
          expect(wrapper.vm.recentSearchesStore.addRecentSearch).toHaveBeenCalledWith(mockFilters);
        });
      });

      it('calls `recentSearchesService.save` with array of searches', async () => {
        jest.spyOn(wrapper.vm.recentSearchesService, 'save');

        wrapper.vm.handleFilterSubmit();

        await nextTick();

        return wrapper.vm.recentSearchesPromise.then(() => {
          expect(wrapper.vm.recentSearchesService.save).toHaveBeenCalledWith([mockFilters]);
        });
      });

      it('sets `recentSearches` data prop with array of searches', () => {
        jest.spyOn(wrapper.vm.recentSearchesService, 'save');

        wrapper.vm.handleFilterSubmit();

        return wrapper.vm.recentSearchesPromise.then(() => {
          expect(wrapper.vm.recentSearches).toEqual([mockFilters]);
        });
      });

      it('calls `blurSearchInput` method to remove focus from filter input field', () => {
        jest.spyOn(wrapper.vm, 'blurSearchInput');

        findGlFilteredSearch().vm.$emit('submit', mockFilters);

        expect(wrapper.vm.blurSearchInput).toHaveBeenCalled();
      });

      it('emits component event `onFilter` with provided filters param', async () => {
        jest.spyOn(wrapper.vm, 'removeQuotesEnclosure');

        findGlFilteredSearch().vm.$emit('submit');
        await nextTick();

        expect(wrapper.emitted('onFilter')[0]).toEqual([mockFilters]);
        expect(wrapper.vm.removeQuotesEnclosure).toHaveBeenCalledWith(mockFilters);
      });
    });
  });

  describe('template', () => {
    it('renders gl-filtered-search component', async () => {
      wrapper = createComponent();
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      await wrapper.setData({
        recentSearches: mockHistoryItems,
      });

      const glFilteredSearchEl = wrapper.findComponent(GlFilteredSearch);

      expect(glFilteredSearchEl.props('placeholder')).toBe('Filter requirements');
      expect(glFilteredSearchEl.props('availableTokens')).toEqual(mockAvailableTokens);
      expect(glFilteredSearchEl.props('historyItems')).toEqual(mockHistoryItems);
    });

    it('renders checkbox when `showCheckbox` prop is true', () => {
      let wrapperWithCheckbox = createComponent({
        showCheckbox: true,
      });

      expect(wrapperWithCheckbox.findComponent(GlFormCheckbox).exists()).toBe(true);
      expect(
        wrapperWithCheckbox.findComponent(GlFormCheckbox).attributes('checked'),
      ).not.toBeDefined();

      wrapperWithCheckbox.destroy();

      wrapperWithCheckbox = createComponent({
        showCheckbox: true,
        checkboxChecked: true,
      });

      expect(wrapperWithCheckbox.findComponent(GlFormCheckbox).attributes('checked')).toBe('true');

      wrapperWithCheckbox.destroy();
    });

    it('renders search history items dropdown with formatting done using token symbols', async () => {
      const wrapperFullMount = createComponent({ sortOptions: mockSortOptions, shallow: false });
      wrapperFullMount.vm.recentSearchesStore.addRecentSearch(mockHistoryItems[0]);

      await nextTick();

      const searchHistoryItemsEl = wrapperFullMount.findAll(
        '.gl-search-box-by-click-menu .gl-search-box-by-click-history-item',
      );

      expect(searchHistoryItemsEl.at(0).text()).toBe(
        'Author := @rootLabel := ~bugMilestone := %v1.0"duo"',
      );

      wrapperFullMount.destroy();
    });

    describe('when token options have `title` attribute defined', () => {
      it('renders search history items using the provided `title` attribute', async () => {
        const wrapperFullMount = createComponent({
          sortOptions: mockSortOptions,
          tokens: [mockMembershipToken],
          shallow: false,
        });

        wrapperFullMount.vm.recentSearchesStore.addRecentSearch([tokenValueMembership]);

        await nextTick();

        expect(wrapperFullMount.findComponent(GlDropdownItem).text()).toBe('Membership := Direct');

        wrapperFullMount.destroy();
      });
    });

    describe('when token options have do not have `title` attribute defined', () => {
      it('renders search history items using the provided `value` attribute', async () => {
        const wrapperFullMount = createComponent({
          sortOptions: mockSortOptions,
          tokens: [mockMembershipTokenOptionsWithoutTitles],
          shallow: false,
        });

        wrapperFullMount.vm.recentSearchesStore.addRecentSearch([tokenValueMembership]);

        await nextTick();

        expect(wrapperFullMount.findComponent(GlDropdownItem).text()).toBe('Membership := exclude');

        wrapperFullMount.destroy();
      });
    });

    it('renders sort dropdown component', () => {
      wrapper = createComponent({ sortOptions: mockSortOptions });

      expect(findGlSorting().exists()).toBe(true);
    });

    it('renders sort dropdown items', () => {
      wrapper = createComponent({ sortOptions: mockSortOptions });

      const { sortOptions, sortBy } = findGlSorting().props();

      expect(sortOptions).toEqual([
        {
          value: mockSortOptions[0].id,
          text: mockSortOptions[0].title,
        },
        {
          value: mockSortOptions[1].id,
          text: mockSortOptions[1].title,
        },
      ]);

      expect(sortBy).toBe(mockSortOptions[0].id);
    });
  });

  describe('watchers', () => {
    const tokenValue = {
      id: 'id-1',
      type: FILTERED_SEARCH_TERM,
      value: { data: '' },
    };

    beforeEach(() => {
      wrapper = createComponent({ sortOptions: mockSortOptions });
    });

    it('syncs filter value', async () => {
      await wrapper.setProps({ initialFilterValue: [tokenValue], syncFilterAndSort: true });

      expect(findGlFilteredSearch().props('value')).toEqual([tokenValue]);
    });

    it('does not sync filter value when syncFilterAndSort=false', async () => {
      await wrapper.setProps({ initialFilterValue: [tokenValue], syncFilterAndSort: false });

      expect(findGlFilteredSearch().props('value')).toEqual([]);
    });

    it('syncs sort values', async () => {
      await wrapper.setProps({ initialSortBy: 'updated_asc', syncFilterAndSort: true });

      expect(findGlSorting().props()).toMatchObject({
        sortBy: 2,
        isAscending: true,
      });
    });

    it('does not sync sort values when syncFilterAndSort=false', async () => {
      await wrapper.setProps({ initialSortBy: 'updated_asc', syncFilterAndSort: false });

      expect(findGlSorting().props()).toMatchObject({
        sortBy: 1,
        isAscending: false,
      });
    });

    it('does not sync sort values when initialSortBy is unset', async () => {
      // Give initialSort some value which changes the current sort option...
      await wrapper.setProps({ initialSortBy: 'updated_asc', syncFilterAndSort: true });

      // ... Read the new sort options...
      const { sortBy, isAscending } = findGlSorting().props();

      // ... Then *unset* initialSortBy...
      await wrapper.setProps({ initialSortBy: undefined });

      // ... The sort options should not have changed.
      expect(findGlSorting().props()).toMatchObject({ sortBy, isAscending });
    });
  });
});
