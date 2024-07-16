import { GlDisclosureDropdownItem, GlSorting, GlFilteredSearch, GlFormCheckbox } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import waitForPromises from 'helpers/wait_for_promises';

import RecentSearchesService from '~/filtered_search/services/recent_searches_service';
import {
  FILTERED_SEARCH_TERM,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBarRoot from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { uniqueTokens } from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import { RECENT_SEARCHES_STORAGE_KEY_GROUPS } from '~/filtered_search/recent_searches_storage_keys';

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

const mockFetch = jest.fn().mockResolvedValue([]);
const mockServiceResults = (results) => {
  mockFetch.mockResolvedValueOnce(results);
};

jest.mock('~/filtered_search/services/recent_searches_service', () => {
  const ServiceMock = jest.fn(function ServiceMock() {
    Object.assign(this, {
      fetch: mockFetch,
      save: jest.fn(),
      isAvailable: () => true,
    });
  });
  ServiceMock.isAvailable = () => true;

  return {
    __esModule: true,
    default: ServiceMock,
  };
});

const defaultProps = {
  namespace: 'gitlab-org/gitlab-test',
  recentSearchesStorageKey: 'issues',
  tokens: mockAvailableTokens,
  initialFilterValue: [],
  showCheckbox: false,
  checkboxChecked: false,
  searchInputPlaceholder: 'Filter requirements',
};

describe('FilteredSearchBarRoot', () => {
  useLocalStorageSpy();
  let wrapper;

  const createComponent = ({ shallow = true, propsData = {} } = {}) => {
    const mountMethod = shallow ? shallowMount : mount;

    wrapper = mountMethod(FilteredSearchBarRoot, { propsData: { ...defaultProps, ...propsData } });
  };

  const findGlSorting = () => wrapper.findComponent(GlSorting);
  const findGlFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const findGlFormCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findGlDisclosureDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findGlDisclosureDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  afterEach(() => {
    localStorage.clear();
  });

  describe('data', () => {
    describe('when `sortOptions` are provided', () => {
      beforeEach(() => {
        createComponent({ propsData: { sortOptions: mockSortOptions } });
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
      createComponent();

      expect(findGlSorting().exists()).toBe(false);
    });
  });

  describe('computed', () => {
    describe('tokenSymbols', () => {
      it('returns a map containing type and symbols from `tokens` prop', () => {
        createComponent();
        expect(wrapper.vm.tokenSymbols).toEqual({
          [TOKEN_TYPE_AUTHOR]: '@',
          [TOKEN_TYPE_LABEL]: '~',
          [TOKEN_TYPE_MILESTONE]: '%',
        });
      });
    });

    describe('tokenTitles', () => {
      it('returns a map containing type and title from `tokens` prop', () => {
        createComponent();
        expect(wrapper.vm.tokenTitles).toEqual({
          [TOKEN_TYPE_AUTHOR]: 'Author',
          [TOKEN_TYPE_LABEL]: 'Label',
          [TOKEN_TYPE_MILESTONE]: 'Milestone',
        });
      });
    });

    describe('sortDirectionIcon', () => {
      beforeEach(() => {
        createComponent({ propsData: { sortOptions: mockSortOptions } });
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
      it('returns array of recent searches filtering out any string type (unsupported) items', async () => {
        mockServiceResults([{ foo: 'bar' }, 'foo']);
        createComponent();
        await nextTick();

        expect(wrapper.vm.filteredRecentSearches).toHaveLength(1);
        expect(wrapper.vm.filteredRecentSearches[0]).toEqual({ foo: 'bar' });
      });

      it('returns array of recent searches sanitizing any duplicate token values', async () => {
        mockServiceResults([
          [tokenValueAuthor, tokenValueLabel, tokenValueMilestone, tokenValueLabel],
          [tokenValueAuthor, tokenValueMilestone],
        ]);
        createComponent();
        await nextTick();

        expect(wrapper.vm.filteredRecentSearches).toHaveLength(2);
        expect(uniqueTokens).toHaveBeenCalled();
      });

      it('returns undefined when recentSearchesStorageKey prop is not set on component', async () => {
        createComponent();
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
      createComponent({ propsData: { initialFilterValue: [tokenValueLabel] } });

      wrapper.findComponent(GlFilteredSearch).vm.$emit('clear');

      await nextTick();
      expect(wrapper.emitted('onFilter')[0]).toEqual([[], true]);
    });

    it('emits component event `onInput` on filteredsearch input component', async () => {
      const mockFilters = [tokenValueAuthor, 'foo'];
      createComponent();

      wrapper.findComponent(GlFilteredSearch).vm.$emit('input', mockFilters);

      await nextTick();

      expect(wrapper.emitted('onInput')[0]).toEqual([mockFilters]);
    });
  });

  describe('methods', () => {
    describe('setupRecentSearch', () => {
      describe('when `recentSearchesStorageKey` is changed', () => {
        it('reinitializes storage service', async () => {
          createComponent();
          expect(RecentSearchesService).toHaveBeenLastCalledWith(
            'gitlab-org/gitlab-test-issue-recent-searches',
          );

          await wrapper.setProps({ recentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_GROUPS });

          expect(RecentSearchesService).toHaveBeenLastCalledWith(
            'gitlab-org/gitlab-test-groups-recent-searches',
          );
        });
      });
    });

    describe('removeQuotesEnclosure', () => {
      const mockFilters = [tokenValueAuthor, tokenValueLabel, tokenValueConfidential, 'foo'];

      it('returns filter array with unescaped strings for values which have spaces', () => {
        createComponent();
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
        createComponent({ propsData: { sortOptions: mockSortOptions } });

        findGlSorting().vm.$emit('sortByChange', mockSortOptions[1].id);
        await nextTick();

        expect(wrapper.vm.selectedSortOption).toBe(mockSortOptions[1]);
        expect(wrapper.emitted('onSort')[0]).toEqual([mockSortOptions[1].sortDirection.descending]);
      });
    });

    describe('handleSortDirectionChange', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            sortOptions: mockSortOptions,
            initialSortBy: mockSortOptions[0].sortDirection.descending,
          },
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
        createComponent();
        expect(wrapper.emitted('onFilter')).toEqual(undefined);
        findGlFilteredSearch().vm.$emit('history-item-selected', mockHistoryItems[0]);
        expect(wrapper.emitted('onFilter')[0]).toEqual([mockHistoryItems[0]]);
      });
    });

    describe('handleClearHistory', () => {
      it('clears search history from recent searches store', () => {
        createComponent();
        jest.spyOn(wrapper.vm.recentSearchesStore, 'setRecentSearches').mockReturnValue([]);
        findGlFilteredSearch().vm.$emit('clear-history');

        expect(wrapper.vm.recentSearchesStore.setRecentSearches).toHaveBeenCalledWith([]);
        expect(wrapper.vm.recentSearches).toEqual([]);
      });
    });

    describe('handleFilterSubmit', () => {
      const mockFilters = [tokenValueAuthor, 'foo'];

      beforeEach(async () => {
        createComponent({ propsData: { initialFilterValue: mockFilters } });
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
        findGlFilteredSearch().vm.$emit('submit');
        await waitForPromises();

        const { save } = RecentSearchesService.mock.instances.at(-1);
        expect(save).toHaveBeenLastCalledWith([mockFilters]);
      });

      it('calls `blurSearchInput` method to remove focus from filter input field', () => {
        jest.spyOn(wrapper.vm, 'blurSearchInput');

        findGlFilteredSearch().vm.$emit('submit', mockFilters);

        expect(wrapper.vm.blurSearchInput).toHaveBeenCalled();
      });

      it('emits component event `onFilter` with provided filters param', async () => {
        expect(wrapper.emitted('onFilter')).toEqual(undefined);
        findGlFilteredSearch().vm.$emit('submit');
        await nextTick();

        expect(wrapper.emitted('onFilter')[0]).toEqual([mockFilters]);
      });
    });
  });

  describe('template', () => {
    it('renders gl-filtered-search component', async () => {
      mockServiceResults(mockHistoryItems);
      createComponent();
      await nextTick();
      await nextTick();

      const glFilteredSearchEl = wrapper.findComponent(GlFilteredSearch);

      expect(glFilteredSearchEl.props('placeholder')).toBe('Filter requirements');
      expect(glFilteredSearchEl.props('availableTokens')).toEqual(mockAvailableTokens);
      expect(glFilteredSearchEl.props('historyItems')).toEqual(mockHistoryItems);
    });

    it('renders unchecked checkbox when `showCheckbox` prop is true', () => {
      createComponent({ propsData: { showCheckbox: true } });
      expect(findGlFormCheckbox().exists()).toBe(true);
      expect(findGlFormCheckbox().attributes('checked')).not.toBeDefined();
    });

    it('renders checked checkbox when `checkboxChecked` prop is true', () => {
      createComponent({ propsData: { showCheckbox: true, checkboxChecked: true } });
      expect(findGlFormCheckbox().attributes('checked')).toBe('true');
    });

    it('renders search history items dropdown with formatting done using token symbols', async () => {
      createComponent({ propsData: { sortOptions: mockSortOptions }, shallow: false });
      wrapper.vm.recentSearchesStore.addRecentSearch(mockHistoryItems[0]);
      await nextTick();

      expect(findGlDisclosureDropdownItems().at(0).text()).toBe(
        'Author := @rootLabel := ~bugMilestone := %v1.0"duo"',
      );
    });

    describe('when token options have `title` attribute defined', () => {
      it('renders search history items using the provided `title` attribute', async () => {
        createComponent({
          propsData: {
            sortOptions: mockSortOptions,
            tokens: [mockMembershipToken],
          },
          shallow: false,
        });

        wrapper.vm.recentSearchesStore.addRecentSearch([tokenValueMembership]);
        await nextTick();
        expect(findGlDisclosureDropdownItem().text()).toBe('Membership := Direct');
      });
    });

    describe('when token options have do not have `title` attribute defined', () => {
      it('renders search history items using the provided `value` attribute', async () => {
        createComponent({
          propsData: {
            sortOptions: mockSortOptions,
            tokens: [mockMembershipTokenOptionsWithoutTitles],
          },
          shallow: false,
        });
        wrapper.vm.recentSearchesStore.addRecentSearch([tokenValueMembership]);
        await nextTick();
        expect(findGlDisclosureDropdownItem().text()).toBe('Membership := exclude');
      });
    });

    it('renders sort dropdown component', () => {
      createComponent({ propsData: { sortOptions: mockSortOptions } });

      expect(findGlSorting().exists()).toBe(true);
    });

    it('renders sort dropdown items', () => {
      createComponent({ propsData: { sortOptions: mockSortOptions } });

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

    describe('showSearchButton', () => {
      it('sets showSearchButton on the filteredsearch component when provided', () => {
        createComponent({ propsData: { showSearchButton: false } });
        expect(findGlFilteredSearch().props('showSearchButton')).toBe(false);
      });

      it('sets defaults to true', () => {
        createComponent();
        expect(findGlFilteredSearch().props('showSearchButton')).toBe(true);
      });
    });
  });

  describe('watchers', () => {
    const tokenValue = {
      id: 'id-1',
      type: FILTERED_SEARCH_TERM,
      value: { data: '' },
    };

    beforeEach(() => {
      createComponent({ propsData: { sortOptions: mockSortOptions } });
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
