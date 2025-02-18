import { GlAlert, GlKeysetPagination, GlPagination, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueDraggable from 'vuedraggable';
import { TEST_HOST } from 'helpers/test_constants';
import { DRAG_DELAY } from '~/sortable/constants';
import EmptyResult from '~/vue_shared/components/empty_result.vue';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import PageSizeSelector from '~/vue_shared/components/page_size_selector.vue';
import IssuableBulkEditSidebar from '~/vue_shared/issuable/list/components/issuable_bulk_edit_sidebar.vue';
import IssuableGrid from '~/vue_shared/issuable/list/components/issuable_grid.vue';
import IssuableItem from '~/vue_shared/issuable/list/components/issuable_item.vue';
import IssuableListRoot from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import IssuableTabs from '~/vue_shared/issuable/list/components/issuable_tabs.vue';
import { mockIssuableListProps } from '../mock_data';

describe('IssuableListRoot component', () => {
  /** @type {import('@vue/test-utils').Wrapper} */
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findAllIssuableItems = () => wrapper.findAllComponents(IssuableItem);
  const findFilteredSearchBar = () => wrapper.findComponent(FilteredSearchBar);
  const findGlKeysetPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findGlPagination = () => wrapper.findComponent(GlPagination);
  const findIssuableGrid = () => wrapper.findComponent(IssuableGrid);
  const findIssuableItem = () => wrapper.findComponent(IssuableItem);
  const findIssuableTabs = () => wrapper.findComponent(IssuableTabs);
  const findPageSizeSelector = () => wrapper.findComponent(PageSizeSelector);
  const findVueDraggable = () => wrapper.findComponent(VueDraggable);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(IssuableListRoot, {
      propsData: {
        ...mockIssuableListProps,
        ...props,
      },
      slots: {
        'nav-actions': `<button class="js-new-issuable">New issuable</button>`,
        'empty-state': `<p class="js-issuable-empty-state">Issuable empty state</p>`,
      },
    });
  };

  describe('IssuableTabs component', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders', () => {
      expect(findIssuableTabs().props()).toEqual({
        tabs: mockIssuableListProps.tabs,
        tabCounts: mockIssuableListProps.tabCounts,
        currentTab: mockIssuableListProps.currentTab,
        truncateCounts: false,
        addPadding: false,
      });
    });

    it('emits "click-tab" event on "click-tab" event', () => {
      findIssuableTabs().vm.$emit('click');

      expect(wrapper.emitted('click-tab')).toEqual([[]]);
    });

    it('renders contents for slot "nav-actions" within IssuableTab component', () => {
      expect(findIssuableTabs().find('.js-new-issuable').text()).toBe('New issuable');
    });

    it('sets "addPadding" prop correctly when updated', async () => {
      await wrapper.setProps({ addPadding: true });

      expect(findIssuableTabs().props('addPadding')).toBe(true);
    });
  });

  describe('FilteredSearchBar component', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders', () => {
      expect(findFilteredSearchBar().props()).toMatchObject({
        namespace: 'gitlab-org/gitlab-test',
        recentSearchesStorageKey: 'issues',
        searchInputPlaceholder: 'Search issues',
        sortOptions: mockIssuableListProps.sortOptions,
        initialFilterValue: [],
        initialSortBy: 'created_desc',
        syncFilterAndSort: false,
        showCheckbox: false,
        checkboxChecked: false,
        showFriendlyText: false,
        termsAsTokens: true,
      });
    });

    describe('when "checked-input" event is emitted', () => {
      it('sets all issuables to checked', async () => {
        findFilteredSearchBar().vm.$emit('checked-input', true);
        await nextTick();

        expect(findFilteredSearchBar().props('checkboxChecked')).toBe(true);
        expect(
          findAllIssuableItems().filter((component) => component.props('checked') === true),
        ).toHaveLength(5);
      });

      it('emits "update-legacy-bulk-edit" event', () => {
        findFilteredSearchBar().vm.$emit('checked-input', true);

        expect(wrapper.emitted('update-legacy-bulk-edit')).toEqual([[]]);
      });
    });

    it('emits "filter" event when "onFilter" event is emitted', () => {
      findFilteredSearchBar().vm.$emit('onFilter');

      expect(wrapper.emitted('filter')).toEqual([[]]);
    });

    it('emits "sort" event when "onSort" event is emitted', () => {
      findFilteredSearchBar().vm.$emit('onSort');

      expect(wrapper.emitted('sort')).toEqual([[]]);
    });
  });

  describe('alert', () => {
    const error = 'oopsie!';

    it('shows an alert when there is an error', () => {
      createComponent({ error });

      expect(findAlert().text()).toBe(error);
    });

    it('does not render when there is no error', () => {
      createComponent();

      expect(findAlert().exists()).toBe(false);
    });

    it('emits "dismiss-alert" event when dismissed', () => {
      createComponent({ error });

      findAlert().vm.$emit('dismiss');

      expect(wrapper.emitted('dismiss-alert')).toEqual([[]]);
    });
  });

  it('renders IssuableBulkEditSidebar component', () => {
    createComponent();

    expect(wrapper.findComponent(IssuableBulkEditSidebar).exists()).toBe(true);
  });

  it('renders skeleton loader when in loading state', () => {
    createComponent({ issuablesLoading: true });

    expect(wrapper.findAllComponents(GlSkeletonLoader)).toHaveLength(
      mockIssuableListProps.issuables.length,
    );
  });

  describe('manual ordering', () => {
    describe('when enabled', () => {
      beforeEach(() => {
        createComponent({ isManualOrdering: true });
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
      it('does not render VueDraggable component', () => {
        createComponent();

        expect(findVueDraggable().exists()).toBe(false);
      });
    });
  });

  describe('IssuableItem component', () => {
    it('renders for each issuable', () => {
      createComponent();
      const issuableItems = findAllIssuableItems();

      expect(issuableItems).toHaveLength(mockIssuableListProps.issuables.length);
      expect(issuableItems.at(0).props()).toEqual({
        hasScopedLabelsFeature: false,
        issuableSymbol: '#',
        issuable: mockIssuableListProps.issuables[0],
        labelFilterParam: 'label_name',
        showCheckbox: false,
        checked: false,
        showWorkItemTypeIcon: false,
        preventRedirect: false,
        isActive: false,
        fullPath: null,
      });
    });

    describe('isActive prop', () => {
      it('is false if there is no active issuable', () => {
        createComponent();

        expect(findIssuableItem().props('isActive')).toBe(false);
      });

      it('is true if active issuable matches issuable item', () => {
        createComponent({ activeIssuable: mockIssuableListProps.issuables[0] });

        expect(findIssuableItem().props('isActive')).toBe(true);
      });
    });

    it('emits "update-legacy-bulk-edit" event when "checked-input" event is emitted', () => {
      createComponent();

      findIssuableItem().vm.$emit('checked-input');

      expect(wrapper.emitted('update-legacy-bulk-edit')).toEqual([[]]);
    });

    it('emits "select-issuable" event when "select-issuable" event is emitted', () => {
      const issuable = mockIssuableListProps.issuables[0];
      createComponent();

      findIssuableItem().vm.$emit('select-issuable', issuable);

      expect(wrapper.emitted('select-issuable')).toEqual([[issuable]]);
    });
  });

  it('renders IssuableGrid component when in grid view context', () => {
    createComponent({ isGridView: true });

    expect(findIssuableGrid().exists()).toBe(true);
  });

  it('renders contents for slot "empty-state" when there are no issuables', () => {
    createComponent({ issuables: [] });

    expect(wrapper.find('p.js-issuable-empty-state').text()).toBe('Issuable empty state');
  });

  it('renders EmptyResult when there are no search results', () => {
    createComponent({ issuables: [], initialFilterValue: ['test'] });

    expect(wrapper.findComponent(EmptyResult).exists()).toBe(true);
  });

  describe('pagination', () => {
    describe('GlKeysetPagination component', () => {
      it('renders only when "showPaginationControls" and "useKeysetPagination" props are true', () => {
        createComponent({
          hasNextPage: true,
          hasPreviousPage: true,
          showPaginationControls: true,
          useKeysetPagination: true,
        });

        expect(findGlPagination().exists()).toBe(false);
        expect(findGlKeysetPagination().props()).toMatchObject({
          hasNextPage: true,
          hasPreviousPage: true,
        });
      });

      it.each`
        event              | glKeysetPaginationEvent
        ${'next-page'}     | ${'next'}
        ${'previous-page'} | ${'prev'}
      `(
        'emits "$event" event when "$glKeysetPaginationEvent" event is emitted',
        ({ event, glKeysetPaginationEvent }) => {
          createComponent({ showPaginationControls: true, useKeysetPagination: true });

          findGlKeysetPagination().vm.$emit(glKeysetPaginationEvent);

          expect(wrapper.emitted(event)).toEqual([[]]);
        },
      );
    });

    describe('GlPagination component', () => {
      it('renders only when "showPaginationControls" prop is true', () => {
        createComponent({
          showPaginationControls: true,
          totalItems: 10,
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

      it('emits "page-change" event when "input" event is emitted', () => {
        createComponent({ showPaginationControls: true });

        findGlPagination().vm.$emit('input');

        expect(wrapper.emitted('page-change')).toEqual([[]]);
      });
    });
  });

  describe('PageSizeSelector component', () => {
    beforeEach(() => {
      createComponent({ showPageSizeSelector: true });
    });

    it('renders', () => {
      expect(findPageSizeSelector().exists()).toBe(true);
    });

    it('emits "page-size-change" event when "input" event is emitted', () => {
      const pageSize = 123;

      findPageSizeSelector().vm.$emit('input', pageSize);

      expect(wrapper.emitted('page-size-change')).toEqual([[pageSize]]);
    });
  });

  describe('watchers', () => {
    describe('urlParams', () => {
      beforeEach(() => {
        createComponent();
      });

      it('updates URL when "urlParams" prop updates', async () => {
        const urlParams = {
          state: 'closed',
          sort: 'updated_asc',
          page: 1,
          search: 'foo',
        };

        await wrapper.setProps({ urlParams });

        expect(global.window.location.href).toBe(
          `${TEST_HOST}/?state=${urlParams.state}&sort=${urlParams.sort}&page=${urlParams.page}&search=${urlParams.search}`,
        );
      });
    });
  });
});
