import {
  GlFilteredSearch,
  GlButtonGroup,
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlFormCheckbox,
} from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';

import RecentSearchesService from '~/filtered_search/services/recent_searches_service';
import RecentSearchesStore from '~/filtered_search/stores/recent_searches_store';
import { SortDirection } from '~/vue_shared/components/filtered_search_bar/constants';
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
  stripQuotes: jest.requireActual(
    '~/vue_shared/components/filtered_search_bar/filtered_search_utils',
  ).stripQuotes,
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
      showCheckbox,
      checkboxChecked,
      searchInputPlaceholder,
    },
  });
};

describe('FilteredSearchBarRoot', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent({ sortOptions: mockSortOptions });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('data', () => {
    it('initializes `filterValue`, `selectedSortOption` and `selectedSortDirection` data props and displays the sort dropdown', () => {
      expect(wrapper.vm.filterValue).toEqual([]);
      expect(wrapper.vm.selectedSortOption).toBe(mockSortOptions[0].sortDirection.descending);
      expect(wrapper.vm.selectedSortDirection).toBe(SortDirection.descending);
      expect(wrapper.find(GlButtonGroup).exists()).toBe(true);
      expect(wrapper.find(GlButton).exists()).toBe(true);
      expect(wrapper.find(GlDropdown).exists()).toBe(true);
      expect(wrapper.find(GlDropdownItem).exists()).toBe(true);
    });

    it('does not initialize `selectedSortOption` and `selectedSortDirection` when `sortOptions` is not applied and hides the sort dropdown', () => {
      const wrapperNoSort = createComponent();

      expect(wrapperNoSort.vm.filterValue).toEqual([]);
      expect(wrapperNoSort.vm.selectedSortOption).toBe(undefined);
      expect(wrapperNoSort.find(GlButtonGroup).exists()).toBe(false);
      expect(wrapperNoSort.find(GlButton).exists()).toBe(false);
      expect(wrapperNoSort.find(GlDropdown).exists()).toBe(false);
      expect(wrapperNoSort.find(GlDropdownItem).exists()).toBe(false);
    });
  });

  describe('computed', () => {
    describe('tokenSymbols', () => {
      it('returns a map containing type and symbols from `tokens` prop', () => {
        expect(wrapper.vm.tokenSymbols).toEqual({
          author_username: '@',
          label_name: '~',
          milestone_title: '%',
        });
      });
    });

    describe('tokenTitles', () => {
      it('returns a map containing type and title from `tokens` prop', () => {
        expect(wrapper.vm.tokenTitles).toEqual({
          author_username: 'Author',
          label_name: 'Label',
          milestone_title: 'Milestone',
        });
      });
    });

    describe('sortDirectionIcon', () => {
      it('returns string "sort-lowest" when `selectedSortDirection` is "ascending"', () => {
        wrapper.setData({
          selectedSortDirection: SortDirection.ascending,
        });

        expect(wrapper.vm.sortDirectionIcon).toBe('sort-lowest');
      });

      it('returns string "sort-highest" when `selectedSortDirection` is "descending"', () => {
        wrapper.setData({
          selectedSortDirection: SortDirection.descending,
        });

        expect(wrapper.vm.sortDirectionIcon).toBe('sort-highest');
      });
    });

    describe('sortDirectionTooltip', () => {
      it('returns string "Sort direction: Ascending" when `selectedSortDirection` is "ascending"', () => {
        wrapper.setData({
          selectedSortDirection: SortDirection.ascending,
        });

        expect(wrapper.vm.sortDirectionTooltip).toBe('Sort direction: Ascending');
      });

      it('returns string "Sort direction: Descending" when `selectedSortDirection` is "descending"', () => {
        wrapper.setData({
          selectedSortDirection: SortDirection.descending,
        });

        expect(wrapper.vm.sortDirectionTooltip).toBe('Sort direction: Descending');
      });
    });

    describe('filteredRecentSearches', () => {
      it('returns array of recent searches filtering out any string type (unsupported) items', async () => {
        wrapper.setData({
          recentSearches: [{ foo: 'bar' }, 'foo'],
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.filteredRecentSearches).toHaveLength(1);
        expect(wrapper.vm.filteredRecentSearches[0]).toEqual({ foo: 'bar' });
      });

      it('returns array of recent searches sanitizing any duplicate token values', async () => {
        wrapper.setData({
          recentSearches: [
            [tokenValueAuthor, tokenValueLabel, tokenValueMilestone, tokenValueLabel],
            [tokenValueAuthor, tokenValueMilestone],
          ],
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.filteredRecentSearches).toHaveLength(2);
        expect(uniqueTokens).toHaveBeenCalled();
      });

      it('returns undefined when recentSearchesStorageKey prop is not set on component', async () => {
        wrapper.setProps({
          recentSearchesStorageKey: '',
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.filteredRecentSearches).not.toBeDefined();
      });
    });
  });

  describe('watchers', () => {
    describe('filterValue', () => {
      it('emits component event `onFilter` with empty array when `filterValue` is cleared by GlFilteredSearch', () => {
        wrapper.setData({
          initialRender: false,
          filterValue: [
            {
              type: 'filtered-search-term',
              value: { data: '' },
            },
          ],
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.emitted('onFilter')[0]).toEqual([[]]);
        });
      });
    });
  });

  describe('methods', () => {
    describe('setupRecentSearch', () => {
      it('initializes `recentSearchesService` and `recentSearchesStore` props when `recentSearchesStorageKey` is available', () => {
        expect(wrapper.vm.recentSearchesService instanceof RecentSearchesService).toBe(true);
        expect(wrapper.vm.recentSearchesStore instanceof RecentSearchesStore).toBe(true);
      });

      it('initializes `recentSearchesPromise` prop with a promise by using `recentSearchesService.fetch()`', () => {
        jest
          .spyOn(wrapper.vm.recentSearchesService, 'fetch')
          .mockReturnValue(new Promise(() => []));

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

    describe('handleSortOptionClick', () => {
      it('emits component event `onSort` with selected sort by value', () => {
        wrapper.vm.handleSortOptionClick(mockSortOptions[1]);

        expect(wrapper.vm.selectedSortOption).toBe(mockSortOptions[1]);
        expect(wrapper.emitted('onSort')[0]).toEqual([mockSortOptions[1].sortDirection.descending]);
      });
    });

    describe('handleSortDirectionClick', () => {
      beforeEach(() => {
        wrapper.setData({
          selectedSortOption: mockSortOptions[0],
        });
      });

      it('sets `selectedSortDirection` to be opposite of its current value', () => {
        expect(wrapper.vm.selectedSortDirection).toBe(SortDirection.descending);

        wrapper.vm.handleSortDirectionClick();

        expect(wrapper.vm.selectedSortDirection).toBe(SortDirection.ascending);
      });

      it('emits component event `onSort` with opposite of currently selected sort by value', () => {
        wrapper.vm.handleSortDirectionClick();

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
        wrapper.setData({
          filterValue: mockFilters,
        });

        await wrapper.vm.$nextTick();
      });

      it('calls `uniqueTokens` on `filterValue` prop to remove duplicates', () => {
        wrapper.vm.handleFilterSubmit();

        expect(uniqueTokens).toHaveBeenCalledWith(wrapper.vm.filterValue);
      });

      it('calls `recentSearchesStore.addRecentSearch` with serialized value of provided `filters` param', () => {
        jest.spyOn(wrapper.vm.recentSearchesStore, 'addRecentSearch');

        wrapper.vm.handleFilterSubmit();

        return wrapper.vm.recentSearchesPromise.then(() => {
          expect(wrapper.vm.recentSearchesStore.addRecentSearch).toHaveBeenCalledWith(mockFilters);
        });
      });

      it('calls `recentSearchesService.save` with array of searches', () => {
        jest.spyOn(wrapper.vm.recentSearchesService, 'save');

        wrapper.vm.handleFilterSubmit();

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

        wrapper.find(GlFilteredSearch).vm.$emit('submit', mockFilters);

        expect(wrapper.vm.blurSearchInput).toHaveBeenCalled();
      });

      it('emits component event `onFilter` with provided filters param', () => {
        jest.spyOn(wrapper.vm, 'removeQuotesEnclosure');

        wrapper.vm.handleFilterSubmit();

        expect(wrapper.emitted('onFilter')[0]).toEqual([mockFilters]);
        expect(wrapper.vm.removeQuotesEnclosure).toHaveBeenCalledWith(mockFilters);
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      wrapper.setData({
        selectedSortOption: mockSortOptions[0],
        selectedSortDirection: SortDirection.descending,
        recentSearches: mockHistoryItems,
      });

      return wrapper.vm.$nextTick();
    });

    it('renders gl-filtered-search component', () => {
      const glFilteredSearchEl = wrapper.find(GlFilteredSearch);

      expect(glFilteredSearchEl.props('placeholder')).toBe('Filter requirements');
      expect(glFilteredSearchEl.props('availableTokens')).toEqual(mockAvailableTokens);
      expect(glFilteredSearchEl.props('historyItems')).toEqual(mockHistoryItems);
    });

    it('renders checkbox when `showCheckbox` prop is true', async () => {
      let wrapperWithCheckbox = createComponent({
        showCheckbox: true,
      });

      expect(wrapperWithCheckbox.find(GlFormCheckbox).exists()).toBe(true);
      expect(wrapperWithCheckbox.find(GlFormCheckbox).attributes('checked')).not.toBeDefined();

      wrapperWithCheckbox.destroy();

      wrapperWithCheckbox = createComponent({
        showCheckbox: true,
        checkboxChecked: true,
      });

      expect(wrapperWithCheckbox.find(GlFormCheckbox).attributes('checked')).toBe('true');

      wrapperWithCheckbox.destroy();
    });

    it('renders search history items dropdown with formatting done using token symbols', async () => {
      const wrapperFullMount = createComponent({ sortOptions: mockSortOptions, shallow: false });
      wrapperFullMount.vm.recentSearchesStore.addRecentSearch(mockHistoryItems[0]);

      await wrapperFullMount.vm.$nextTick();

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

        await wrapperFullMount.vm.$nextTick();

        expect(wrapperFullMount.find(GlDropdownItem).text()).toBe('Membership := Direct');

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

        await wrapperFullMount.vm.$nextTick();

        expect(wrapperFullMount.find(GlDropdownItem).text()).toBe('Membership := exclude');

        wrapperFullMount.destroy();
      });
    });

    it('renders sort dropdown component', () => {
      expect(wrapper.find(GlButtonGroup).exists()).toBe(true);
      expect(wrapper.find(GlDropdown).exists()).toBe(true);
      expect(wrapper.find(GlDropdown).props('text')).toBe(mockSortOptions[0].title);
    });

    it('renders sort dropdown items', () => {
      const dropdownItemsEl = wrapper.findAll(GlDropdownItem);

      expect(dropdownItemsEl).toHaveLength(mockSortOptions.length);
      expect(dropdownItemsEl.at(0).text()).toBe(mockSortOptions[0].title);
      expect(dropdownItemsEl.at(0).props('isChecked')).toBe(true);
      expect(dropdownItemsEl.at(1).text()).toBe(mockSortOptions[1].title);
    });

    it('renders sort direction button', () => {
      const sortButtonEl = wrapper.find(GlButton);

      expect(sortButtonEl.attributes('title')).toBe('Sort direction: Descending');
      expect(sortButtonEl.props('icon')).toBe('sort-highest');
    });
  });
});
