import { GlForm, GlCollapsibleListbox, GlLoadingIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { groupIterationsResponse } from 'jest/work_items/mock_data';
import WorkItemSidebarDropdownWidget from '~/work_items/components/shared/work_item_sidebar_dropdown_widget.vue';

describe('WorkItemSidebarDropdownWidget component', () => {
  let wrapper;

  const findHeader = () => wrapper.find('h3');
  const findEditButton = () => wrapper.findByTestId('edit-button');
  const findApplyButton = () => wrapper.findByTestId('apply-button');

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findLabel = () => wrapper.find('label');
  const findForm = () => wrapper.findComponent(GlForm);
  const findCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  const createComponent = ({
    itemValue = null,
    canUpdate = true,
    isEditing = false,
    updateInProgress = false,
    showFooter = false,
    slots = {},
    multiSelect = false,
    infiniteScroll = false,
    infiniteScrollLoading = false,
    clearSearchOnItemSelect = false,
    listItems = [],
  } = {}) => {
    wrapper = mountExtended(WorkItemSidebarDropdownWidget, {
      propsData: {
        dropdownLabel: 'Iteration',
        dropdownName: 'iteration',
        listItems,
        itemValue,
        canUpdate,
        updateInProgress,
        headerText: 'Select iteration',
        showFooter,
        multiSelect,
        infiniteScroll,
        infiniteScrollLoading,
        clearSearchOnItemSelect,
      },
      slots,
    });

    if (isEditing) {
      findEditButton().vm.$emit('click');
    }
  };

  describe('label', () => {
    it('shows header when not editing', () => {
      createComponent();

      expect(findHeader().exists()).toBe(true);
      expect(findHeader().classes('gl-sr-only')).toBe(false);
      expect(findLabel().exists()).toBe(false);
    });

    it('shows label and hides header while editing', async () => {
      createComponent();

      findEditButton().vm.$emit('click');

      await nextTick();

      expect(findLabel().exists()).toBe(true);
      expect(findHeader().classes('gl-sr-only')).toBe(true);
    });
  });

  describe('edit button', () => {
    it('is not shown if user cannot edit', () => {
      createComponent({ canUpdate: false });

      expect(findEditButton().exists()).toBe(false);
    });

    it('is shown if user can edit', () => {
      createComponent({ canUpdate: true });

      expect(findEditButton().exists()).toBe(true);
    });

    it('triggers edit mode on click', async () => {
      createComponent();

      findEditButton().vm.$emit('click');

      await nextTick();

      expect(findLabel().exists()).toBe(true);
      expect(findForm().exists()).toBe(true);
    });

    it('is replaced by Apply button while editing', async () => {
      createComponent();

      findEditButton().vm.$emit('click');

      await nextTick();

      expect(findEditButton().exists()).toBe(false);
      expect(findApplyButton().exists()).toBe(true);
    });
  });

  describe('loading icon', () => {
    it('shows loading icon while update is in progress', async () => {
      createComponent({ updateInProgress: true });

      await nextTick();

      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('value', () => {
    it('shows None when no item value is set', () => {
      createComponent({ itemValue: null });

      expect(wrapper.text()).toContain('None');
    });
  });

  describe('form', () => {
    it('is not shown while not editing', () => {
      createComponent();

      expect(findForm().exists()).toBe(false);
    });

    it('is shown while editing', async () => {
      createComponent({ isEditing: true });
      await nextTick();

      expect(findForm().exists()).toBe(true);
    });
  });

  describe('Dropdown', () => {
    it('is not shown while not editing', () => {
      createComponent();

      expect(findCollapsibleListbox().exists()).toBe(false);
    });

    it('renders the collapsible listbox with required props', async () => {
      createComponent({ isEditing: true });

      await nextTick();

      expect(findCollapsibleListbox().exists()).toBe(true);
      expect(findCollapsibleListbox().props()).toMatchObject({
        items: [],
        headerText: 'Select iteration',
        category: 'primary',
        loading: false,
        isCheckCentered: true,
        searchable: true,
        searching: false,
        infiniteScroll: false,
        noResultsText: 'No matching results',
        searchPlaceholder: 'Search',
        resetButtonLabel: 'Clear',
      });
    });

    it('renders the footer when enabled', async () => {
      const FOOTER_SLOT_HTML = 'Test message';
      createComponent({ isEditing: true, showFooter: true, slots: { footer: FOOTER_SLOT_HTML } });

      await nextTick();
      expect(wrapper.text()).toContain(FOOTER_SLOT_HTML);
    });

    it('supports multiselect', async () => {
      createComponent({ isEditing: true, multiSelect: true });

      await nextTick();

      expect(findCollapsibleListbox().props('multiple')).toBe(true);
    });

    it('clears search on item select when props passes', async () => {
      const listItems = groupIterationsResponse.data.workspace.attributes.nodes.map((item) => ({
        value: item.id,
        ...item,
      }));
      createComponent({
        isEditing: true,
        clearSearchOnItemSelect: true,
        listItems,
        multiSelect: true,
      });

      await nextTick();

      findCollapsibleListbox().vm.$emit('select', listItems[0].id);

      await nextTick();

      expect(wrapper.emitted('searchStarted')).toEqual([[''], ['']]);
    });

    it('supports infinite scrolling', async () => {
      createComponent({ isEditing: true, infiniteScroll: true });

      await nextTick();

      expect(findCollapsibleListbox().props('infiniteScroll')).toBe(true);
    });

    it('shows loader when bottom reached', async () => {
      createComponent({ isEditing: true, infiniteScroll: true, infiniteScrollLoading: true });

      await nextTick();

      expect(findCollapsibleListbox().props('infiniteScrollLoading')).toBe(true);
    });

    it('displays default dropdown label when no value is selected', async () => {
      createComponent({ isEditing: true });

      await nextTick();

      expect(findCollapsibleListbox().props('toggleText')).toBe('No iteration');
    });
  });

  describe('watcher', () => {
    describe('when createdLabelId prop is updated', () => {
      it('appends itself to the selected items list', async () => {
        createComponent({
          isEditing: true,
          itemValue: ['gid://gitlab/Label/11', 'gid://gitlab/Label/22'],
          multiSelect: true,
        });
        await nextTick();

        expect(findCollapsibleListbox().props('selected')).toEqual([
          'gid://gitlab/Label/11',
          'gid://gitlab/Label/22',
        ]);

        await wrapper.setProps({ createdLabelId: 'gid://gitlab/Label/33' });

        expect(findCollapsibleListbox().props('selected')).toEqual([
          'gid://gitlab/Label/11',
          'gid://gitlab/Label/22',
          'gid://gitlab/Label/33',
        ]);
      });
    });
  });
});
