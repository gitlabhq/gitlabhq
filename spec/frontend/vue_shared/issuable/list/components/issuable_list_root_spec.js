import { GlAlert, GlKeysetPagination, GlSkeletonLoader, GlPagination } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import VueDraggable from 'vuedraggable';

import { nextTick } from 'vue';
import { TEST_HOST } from 'helpers/test_constants';
import { DRAG_DELAY } from '~/sortable/constants';

import IssuableItem from '~/vue_shared/issuable/list/components/issuable_item.vue';
import IssuableListRoot from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import issuableGrid from '~/vue_shared/issuable/list/components/issuable_grid.vue';
import IssuableTabs from '~/vue_shared/issuable/list/components/issuable_tabs.vue';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import PageSizeSelector from '~/vue_shared/components/page_size_selector.vue';

import { mockIssuableListProps, mockIssuables } from '../mock_data';

const createComponent = ({ props = {}, data = {} } = {}) =>
  shallowMount(IssuableListRoot, {
    propsData: {
      ...mockIssuableListProps,
      ...props,
    },
    data() {
      return data;
    },
    slots: {
      'nav-actions': `
      <button class="js-new-issuable">New issuable</button>
    `,
      'empty-state': `
      <p class="js-issuable-empty-state">Issuable empty state</p>
    `,
    },
    stubs: {
      IssuableTabs,
    },
  });

describe('IssuableListRoot', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findFilteredSearchBar = () => wrapper.findComponent(FilteredSearchBar);
  const findGlKeysetPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findGlPagination = () => wrapper.findComponent(GlPagination);
  const findIssuableItem = () => wrapper.findComponent(IssuableItem);
  const findIssuableGrid = () => wrapper.findComponent(issuableGrid);
  const findIssuableTabs = () => wrapper.findComponent(IssuableTabs);
  const findVueDraggable = () => wrapper.findComponent(VueDraggable);
  const findPageSizeSelector = () => wrapper.findComponent(PageSizeSelector);

  describe('computed', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    const mockCheckedIssuables = {
      [mockIssuables[0].iid]: { checked: true, issuable: mockIssuables[0] },
      [mockIssuables[1].iid]: { checked: true, issuable: mockIssuables[1] },
      [mockIssuables[2].iid]: { checked: true, issuable: mockIssuables[2] },
    };

    const mIssuables = [mockIssuables[0], mockIssuables[1], mockIssuables[2]];

    describe('skeletonItemCount', () => {
      it.each`
        totalItems | defaultPageSize | currentPage | returnValue
        ${100}     | ${20}           | ${1}        | ${20}
        ${105}     | ${20}           | ${6}        | ${5}
        ${7}       | ${20}           | ${1}        | ${7}
        ${0}       | ${20}           | ${1}        | ${5}
      `(
        'returns $returnValue when totalItems is $totalItems, defaultPageSize is $defaultPageSize and currentPage is $currentPage',
        async ({ totalItems, defaultPageSize, currentPage, returnValue }) => {
          wrapper.setProps({
            totalItems,
            defaultPageSize,
            currentPage,
          });

          await nextTick();

          expect(wrapper.vm.skeletonItemCount).toBe(returnValue);
        },
      );
    });

    describe('allIssuablesChecked', () => {
      it.each`
        checkedIssuables        | issuables     | specTitle        | returnValue
        ${mockCheckedIssuables} | ${mIssuables} | ${'same as'}     | ${true}
        ${{}}                   | ${mIssuables} | ${'not same as'} | ${false}
      `(
        'returns $returnValue when bulkEditIssuables count is $specTitle issuables count',
        async ({ checkedIssuables, issuables, returnValue }) => {
          wrapper.setProps({
            issuables,
          });

          await nextTick();

          // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
          // eslint-disable-next-line no-restricted-syntax
          wrapper.setData({
            checkedIssuables,
          });

          await nextTick();

          expect(wrapper.vm.allIssuablesChecked).toBe(returnValue);
        },
      );
    });

    describe('bulkEditIssuables', () => {
      it('returns array of issuables which have `checked` set to true within checkedIssuables map', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          checkedIssuables: mockCheckedIssuables,
        });

        await nextTick();

        expect(wrapper.vm.bulkEditIssuables).toHaveLength(mIssuables.length);
      });
    });
  });

  describe('watch', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    describe('issuables', () => {
      it('populates `checkedIssuables` prop with all issuables', async () => {
        wrapper.setProps({
          issuables: [mockIssuables[0]],
        });

        await nextTick();

        expect(Object.keys(wrapper.vm.checkedIssuables)).toHaveLength(1);
        expect(wrapper.vm.checkedIssuables[mockIssuables[0].iid]).toEqual({
          checked: false,
          issuable: mockIssuables[0],
        });
      });
    });

    describe('urlParams', () => {
      it('updates window URL reflecting props within `urlParams`', async () => {
        const urlParams = {
          state: 'closed',
          sort: 'updated_asc',
          page: 1,
          search: 'foo',
        };

        wrapper.setProps({
          urlParams,
        });

        await nextTick();

        expect(global.window.location.href).toBe(
          `${TEST_HOST}/?state=${urlParams.state}&sort=${urlParams.sort}&page=${urlParams.page}&search=${urlParams.search}`,
        );
      });
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    describe('issuableId', () => {
      it('returns id value from provided issuable object', () => {
        expect(wrapper.vm.issuableId({ id: 1 })).toBe(1);
        expect(wrapper.vm.issuableId({ iid: 1 })).toBe(1);
        expect(wrapper.vm.issuableId({})).toBeDefined();
      });
    });

    describe('issuableChecked', () => {
      it('returns boolean value representing checked status of issuable item', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          checkedIssuables: {
            [mockIssuables[0].iid]: { checked: true, issuable: mockIssuables[0] },
          },
        });

        await nextTick();

        expect(wrapper.vm.issuableChecked(mockIssuables[0])).toBe(true);
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class "issuable-list-container"', () => {
      wrapper = createComponent();

      expect(wrapper.classes()).toContain('issuable-list-container');
    });

    it('renders issuable-tabs component', () => {
      wrapper = createComponent();

      const tabsEl = findIssuableTabs();

      expect(tabsEl.exists()).toBe(true);
      expect(tabsEl.props()).toMatchObject({
        tabs: wrapper.vm.tabs,
        tabCounts: wrapper.vm.tabCounts,
        currentTab: wrapper.vm.currentTab,
      });
    });

    it('renders contents for slot "nav-actions" within issuable-tab component', () => {
      wrapper = createComponent();

      const buttonEl = findIssuableTabs().find('button.js-new-issuable');

      expect(buttonEl.exists()).toBe(true);
      expect(buttonEl.text()).toBe('New issuable');
    });

    it('renders filtered-search-bar component', () => {
      wrapper = createComponent();

      const searchEl = findFilteredSearchBar();
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

    it('renders gl-loading-icon when `issuablesLoading` prop is true', () => {
      wrapper = createComponent({ props: { issuablesLoading: true } });

      expect(wrapper.findAllComponents(GlSkeletonLoader)).toHaveLength(
        wrapper.vm.skeletonItemCount,
      );
    });

    it('renders issuable-item component for each item within `issuables` array', () => {
      wrapper = createComponent();

      const itemsEl = wrapper.findAllComponents(IssuableItem);
      const mockIssuable = mockIssuableListProps.issuables[0];

      expect(itemsEl).toHaveLength(mockIssuableListProps.issuables.length);
      expect(itemsEl.at(0).props()).toMatchObject({
        issuableSymbol: wrapper.vm.issuableSymbol,
        issuable: mockIssuable,
      });
    });

    it('renders contents for slot "empty-state" when `issuablesLoading` is false and `issuables` is empty', () => {
      wrapper = createComponent({ props: { issuables: [] } });

      expect(wrapper.find('p.js-issuable-empty-state').exists()).toBe(true);
      expect(wrapper.find('p.js-issuable-empty-state').text()).toBe('Issuable empty state');
    });

    it('renders only gl-pagination when `showPaginationControls` prop is true', () => {
      wrapper = createComponent({
        props: {
          showPaginationControls: true,
          totalItems: 10,
        },
      });

      expect(findGlKeysetPagination().exists()).toBe(false);
      expect(findPageSizeSelector().exists()).toBe(false);
      expect(findGlPagination().props()).toMatchObject({
        perPage: 20,
        value: 1,
        prevPage: 0,
        nextPage: 2,
        totalItems: 10,
        align: 'center',
      });
    });

    it('renders only gl-keyset-pagination when `showPaginationControls` and `useKeysetPagination` props are true', () => {
      wrapper = createComponent({
        props: {
          hasNextPage: true,
          hasPreviousPage: true,
          showPaginationControls: true,
          useKeysetPagination: true,
        },
      });

      expect(findGlPagination().exists()).toBe(false);
      expect(findGlKeysetPagination().props()).toMatchObject({
        hasNextPage: true,
        hasPreviousPage: true,
      });
    });

    describe('showFilteredSearchFriendlyText prop', () => {
      describe.each([true, false])('when %s', (showFilteredSearchFriendlyText) => {
        it('passes its value to FilteredSearchBar', () => {
          wrapper = createComponent({ props: { showFilteredSearchFriendlyText } });

          expect(findFilteredSearchBar().props('showFriendlyText')).toBe(
            showFilteredSearchFriendlyText,
          );
        });
      });
    });

    describe('alert', () => {
      const error = 'oopsie!';

      it('shows an alert when there is an error', () => {
        wrapper = createComponent({ props: { error } });

        expect(findAlert().text()).toBe(error);
      });

      it('emits "dismiss-alert" event when dismissed', () => {
        wrapper = createComponent({ props: { error } });

        findAlert().vm.$emit('dismiss');

        expect(wrapper.emitted('dismiss-alert')).toEqual([[]]);
      });

      it('does not render when there is no error', () => {
        wrapper = createComponent();

        expect(findAlert().exists()).toBe(false);
      });
    });
  });

  describe('events', () => {
    const data = {
      checkedIssuables: {
        [mockIssuables[0].iid]: { checked: true, issuable: mockIssuables[0] },
      },
    };

    it('issuable-tabs component emits `click-tab` event on `click-tab` event', () => {
      wrapper = createComponent({ data });

      findIssuableTabs().vm.$emit('click');

      expect(wrapper.emitted('click-tab')).toHaveLength(1);
    });

    it('sets all issuables as checked when filtered-search-bar component emits `checked-input` event', () => {
      wrapper = createComponent({ data });

      const searchEl = findFilteredSearchBar();

      searchEl.vm.$emit('checked-input', true);

      expect(searchEl.emitted('checked-input')).toHaveLength(1);
      expect(searchEl.emitted('checked-input').length).toBe(1);

      expect(wrapper.vm.checkedIssuables[mockIssuables[0].iid]).toEqual({
        checked: true,
        issuable: mockIssuables[0],
      });
    });

    it('filtered-search-bar component emits `filter` event on `onFilter` & `sort` event on `onSort` events', () => {
      wrapper = createComponent({ data });

      const searchEl = findFilteredSearchBar();

      searchEl.vm.$emit('onFilter');
      expect(wrapper.emitted('filter')).toHaveLength(1);
      searchEl.vm.$emit('onSort');
      expect(wrapper.emitted('sort')).toHaveLength(1);
    });

    it('sets an issuable as checked when issuable-item component emits `checked-input` event', () => {
      wrapper = createComponent({ data });

      const issuableItem = wrapper.findAllComponents(IssuableItem).at(0);

      issuableItem.vm.$emit('checked-input', true);

      expect(issuableItem.emitted('checked-input')).toHaveLength(1);
      expect(issuableItem.emitted('checked-input').length).toBe(1);

      expect(wrapper.vm.checkedIssuables[mockIssuables[0].iid]).toEqual({
        checked: true,
        issuable: mockIssuables[0],
      });
    });

    it('emits `update-legacy-bulk-edit` when filtered-search-bar checkbox is checked', () => {
      wrapper = createComponent({ data });

      findFilteredSearchBar().vm.$emit('checked-input');

      expect(wrapper.emitted('update-legacy-bulk-edit')).toEqual([[]]);
    });

    it('emits `update-legacy-bulk-edit` when issuable-item checkbox is checked', () => {
      wrapper = createComponent({ data });

      findIssuableItem().vm.$emit('checked-input');

      expect(wrapper.emitted('update-legacy-bulk-edit')).toEqual([[]]);
    });

    it('gl-pagination component emits `page-change` event on `input` event', () => {
      wrapper = createComponent({ data, props: { showPaginationControls: true } });

      findGlPagination().vm.$emit('input');
      expect(wrapper.emitted('page-change')).toHaveLength(1);
    });

    it.each`
      event              | glKeysetPaginationEvent
      ${'next-page'}     | ${'next'}
      ${'previous-page'} | ${'prev'}
    `(
      'emits `$event` event when gl-keyset-pagination emits `$glKeysetPaginationEvent` event',
      ({ event, glKeysetPaginationEvent }) => {
        wrapper = createComponent({
          data,
          props: { showPaginationControls: true, useKeysetPagination: true },
        });

        findGlKeysetPagination().vm.$emit(glKeysetPaginationEvent);

        expect(wrapper.emitted(event)).toEqual([[]]);
      },
    );
  });

  describe('manual sorting', () => {
    describe('when enabled', () => {
      beforeEach(() => {
        wrapper = createComponent({
          props: {
            ...mockIssuableListProps,
            isManualOrdering: true,
          },
        });
      });

      it('renders VueDraggable component', () => {
        expect(findVueDraggable().exists()).toBe(true);
      });

      it('IssuableItem has grab cursor', () => {
        expect(findIssuableItem().classes()).toContain('gl-cursor-grab');
      });

      it('sets delay and delayOnTouchOnly attributes on list', () => {
        expect(findVueDraggable().vm.$attrs.delay).toBe(DRAG_DELAY);
        expect(findVueDraggable().vm.$attrs.delayOnTouchOnly).toBe(true);
      });

      it('emits a "reorder" event when user updates the issue order', () => {
        const oldIndex = 4;
        const newIndex = 6;

        findVueDraggable().vm.$emit('update', { oldIndex, newIndex });

        expect(wrapper.emitted('reorder')).toEqual([[{ oldIndex, newIndex }]]);
      });
    });

    describe('when disabled', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('does not render VueDraggable component', () => {
        expect(findVueDraggable().exists()).toBe(false);
      });
    });
  });

  describe('page size selector', () => {
    beforeEach(() => {
      wrapper = createComponent({
        props: {
          showPageSizeChangeControls: true,
        },
      });
    });

    it('has the page size change component', () => {
      expect(findPageSizeSelector().exists()).toBe(true);
    });

    it('emits "page-size-change" event when its input is changed', () => {
      const pageSize = 123;
      findPageSizeSelector().vm.$emit('input', pageSize);
      expect(wrapper.emitted('page-size-change')).toEqual([[pageSize]]);
    });
  });

  describe('grid view issue', () => {
    beforeEach(() => {
      wrapper = createComponent({
        props: {
          isGridView: true,
        },
      });
    });

    it('renders issuableGrid', () => {
      expect(findIssuableGrid().exists()).toBe(true);
    });
  });

  it('passes `isActive` prop as false if there is no active issuable', () => {
    wrapper = createComponent({});

    expect(findIssuableItem().props('isActive')).toBe(false);
  });

  it('passes `isActive` prop as true if active issuable matches issuable item', () => {
    wrapper = createComponent({
      props: {
        activeIssuable: mockIssuableListProps.issuables[0],
      },
    });

    expect(findIssuableItem().props('isActive')).toBe(true);
  });

  it('emits `select-issuable` event on emitting `select-issuable` from issuable item', () => {
    const mockIssuable = mockIssuableListProps.issuables[0];
    wrapper = createComponent({});
    findIssuableItem().vm.$emit('select-issuable', mockIssuable);

    expect(wrapper.emitted('select-issuable')).toEqual([[mockIssuable]]);
  });
});
