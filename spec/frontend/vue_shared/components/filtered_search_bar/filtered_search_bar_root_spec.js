import { shallowMount } from '@vue/test-utils';
import {
  GlFilteredSearch,
  GlButtonGroup,
  GlButton,
  GlNewDropdown as GlDropdown,
  GlNewDropdownItem as GlDropdownItem,
} from '@gitlab/ui';

import FilteredSearchBarRoot from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { SortDirection } from '~/vue_shared/components/filtered_search_bar/constants';

import RecentSearchesStore from '~/filtered_search/stores/recent_searches_store';
import RecentSearchesService from '~/filtered_search/services/recent_searches_service';

import { mockAvailableTokens, mockSortOptions } from './mock_data';

const createComponent = ({
  namespace = 'gitlab-org/gitlab-test',
  recentSearchesStorageKey = 'requirements',
  tokens = mockAvailableTokens,
  sortOptions = mockSortOptions,
  searchInputPlaceholder = 'Filter requirements',
} = {}) =>
  shallowMount(FilteredSearchBarRoot, {
    propsData: {
      namespace,
      recentSearchesStorageKey,
      tokens,
      sortOptions,
      searchInputPlaceholder,
    },
  });

describe('FilteredSearchBarRoot', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('data', () => {
    it('initializes `filterValue`, `selectedSortOption` and `selectedSortDirection` data props', () => {
      expect(wrapper.vm.filterValue).toEqual([]);
      expect(wrapper.vm.selectedSortOption).toBe(mockSortOptions[0].sortDirection.descending);
      expect(wrapper.vm.selectedSortDirection).toBe(SortDirection.descending);
    });
  });

  describe('computed', () => {
    describe('tokenSymbols', () => {
      it('returns array of map containing type and symbols from `tokens` prop', () => {
        expect(wrapper.vm.tokenSymbols).toEqual({ author_username: '@' });
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

    describe('getRecentSearches', () => {
      it('returns array of strings representing recent searches', () => {
        wrapper.vm.recentSearchesStore.setRecentSearches(['foo']);

        expect(wrapper.vm.getRecentSearches()).toEqual(['foo']);
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

    describe('handleFilterSubmit', () => {
      const mockFilters = [
        {
          type: 'author_username',
          value: {
            data: 'root',
            operator: '=',
          },
        },
        'foo',
      ];

      it('calls `recentSearchesStore.addRecentSearch` with serialized value of provided `filters` param', () => {
        jest.spyOn(wrapper.vm.recentSearchesStore, 'addRecentSearch');
        // jest.spyOn(wrapper.vm.recentSearchesService, 'save');

        wrapper.vm.handleFilterSubmit(mockFilters);

        return wrapper.vm.recentSearchesPromise.then(() => {
          expect(wrapper.vm.recentSearchesStore.addRecentSearch).toHaveBeenCalledWith(
            'author_username:=@root foo',
          );
        });
      });

      it('calls `recentSearchesService.save` with array of searches', () => {
        jest.spyOn(wrapper.vm.recentSearchesService, 'save');

        wrapper.vm.handleFilterSubmit(mockFilters);

        return wrapper.vm.recentSearchesPromise.then(() => {
          expect(wrapper.vm.recentSearchesService.save).toHaveBeenCalledWith([
            'author_username:=@root foo',
          ]);
        });
      });

      it('emits component event `onFilter` with provided filters param', () => {
        wrapper.vm.handleFilterSubmit(mockFilters);

        expect(wrapper.emitted('onFilter')[0]).toEqual([mockFilters]);
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      wrapper.setData({
        selectedSortOption: mockSortOptions[0],
        selectedSortDirection: SortDirection.descending,
      });

      return wrapper.vm.$nextTick();
    });

    it('renders gl-filtered-search component', () => {
      const glFilteredSearchEl = wrapper.find(GlFilteredSearch);

      expect(glFilteredSearchEl.props('placeholder')).toBe('Filter requirements');
      expect(glFilteredSearchEl.props('availableTokens')).toEqual(mockAvailableTokens);
    });

    it('renders sort dropdown component', () => {
      expect(wrapper.find(GlButtonGroup).exists()).toBe(true);
      expect(wrapper.find(GlDropdown).exists()).toBe(true);
      expect(wrapper.find(GlDropdown).props('text')).toBe(mockSortOptions[0].title);
    });

    it('renders dropdown items', () => {
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
