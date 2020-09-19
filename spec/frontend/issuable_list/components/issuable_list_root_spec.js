import { mount } from '@vue/test-utils';
import { GlLoadingIcon, GlPagination } from '@gitlab/ui';

import IssuableListRoot from '~/issuable_list/components/issuable_list_root.vue';
import IssuableTabs from '~/issuable_list/components/issuable_tabs.vue';
import IssuableItem from '~/issuable_list/components/issuable_item.vue';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

import { mockIssuableListProps } from '../mock_data';

const createComponent = (propsData = mockIssuableListProps) =>
  mount(IssuableListRoot, {
    propsData,
    slots: {
      'nav-actions': `
      <button class="js-new-issuable">New issuable</button>
    `,
      'empty-state': `
      <p class="js-issuable-empty-state">Issuable empty state</p>
    `,
    },
  });

describe('IssuableListRoot', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    it('renders component container element with class "issuable-list-container"', () => {
      expect(wrapper.classes()).toContain('issuable-list-container');
    });

    it('renders issuable-tabs component', () => {
      const tabsEl = wrapper.find(IssuableTabs);

      expect(tabsEl.exists()).toBe(true);
      expect(tabsEl.props()).toMatchObject({
        tabs: wrapper.vm.tabs,
        tabCounts: wrapper.vm.tabCounts,
        currentTab: wrapper.vm.currentTab,
      });
    });

    it('renders contents for slot "nav-actions" within issuable-tab component', () => {
      const buttonEl = wrapper.find(IssuableTabs).find('button.js-new-issuable');

      expect(buttonEl.exists()).toBe(true);
      expect(buttonEl.text()).toBe('New issuable');
    });

    it('renders filtered-search-bar component', () => {
      const searchEl = wrapper.find(FilteredSearchBar);
      const {
        namespace,
        recentSearchesStorageKey,
        searchInputPlaceholder,
        searchTokens,
        sortOptions,
        initialFilterValue,
        initialSortBy,
      } = wrapper.vm;

      expect(searchEl.exists()).toBe(true);
      expect(searchEl.props()).toMatchObject({
        namespace,
        recentSearchesStorageKey,
        searchInputPlaceholder,
        tokens: searchTokens,
        sortOptions,
        initialFilterValue,
        initialSortBy,
      });
    });

    it('renders gl-loading-icon when `issuablesLoading` prop is true', async () => {
      wrapper.setProps({
        issuablesLoading: true,
      });

      await wrapper.vm.$nextTick();

      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });

    it('renders issuable-item component for each item within `issuables` array', () => {
      const itemsEl = wrapper.findAll(IssuableItem);
      const mockIssuable = mockIssuableListProps.issuables[0];

      expect(itemsEl).toHaveLength(mockIssuableListProps.issuables.length);
      expect(itemsEl.at(0).props()).toMatchObject({
        issuableSymbol: wrapper.vm.issuableSymbol,
        issuable: mockIssuable,
      });
    });

    it('renders contents for slot "empty-state" when `issuablesLoading` is false and `issuables` is empty', async () => {
      wrapper.setProps({
        issuables: [],
      });

      await wrapper.vm.$nextTick();

      expect(wrapper.find('p.js-issuable-empty-state').exists()).toBe(true);
      expect(wrapper.find('p.js-issuable-empty-state').text()).toBe('Issuable empty state');
    });

    it('renders gl-pagination when `showPaginationControls` prop is true', async () => {
      wrapper.setProps({
        showPaginationControls: true,
      });

      await wrapper.vm.$nextTick();

      const paginationEl = wrapper.find(GlPagination);
      expect(paginationEl.exists()).toBe(true);
      expect(paginationEl.props()).toMatchObject({
        perPage: 20,
        value: 1,
        prevPage: 0,
        nextPage: 2,
        align: 'center',
      });
    });
  });

  describe('events', () => {
    it('issuable-tabs component emits `click-tab` event on `click-tab` event', () => {
      wrapper.find(IssuableTabs).vm.$emit('click');

      expect(wrapper.emitted('click-tab')).toBeTruthy();
    });

    it('filtered-search-bar component emits `filter` event on `onFilter` & `sort` event on `onSort` events', () => {
      const searchEl = wrapper.find(FilteredSearchBar);

      searchEl.vm.$emit('onFilter');
      expect(wrapper.emitted('filter')).toBeTruthy();
      searchEl.vm.$emit('onSort');
      expect(wrapper.emitted('sort')).toBeTruthy();
    });

    it('gl-pagination component emits `page-change` event on `input` event', async () => {
      wrapper.setProps({
        showPaginationControls: true,
      });

      await wrapper.vm.$nextTick();

      wrapper.find(GlPagination).vm.$emit('input');
      expect(wrapper.emitted('page-change')).toBeTruthy();
    });
  });
});
