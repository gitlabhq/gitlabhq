import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import $ from 'jquery';

import { nextTick } from 'vue';
import ClusterFormDropdown from '~/create_cluster/components/cluster_form_dropdown.vue';
import DropdownButton from '~/vue_shared/components/dropdown/dropdown_button.vue';
import DropdownSearchInput from '~/vue_shared/components/dropdown/dropdown_search_input.vue';

describe('ClusterFormDropdown', () => {
  let wrapper;
  const firstItem = { name: 'item 1', value: '1' };
  const secondItem = { name: 'item 2', value: '2' };
  const items = [firstItem, secondItem, { name: 'item 3', value: '3' }];

  beforeEach(() => {
    wrapper = shallowMount(ClusterFormDropdown);
  });
  afterEach(() => wrapper.destroy());

  describe('when initial value is provided', () => {
    it('sets selectedItem to initial value', async () => {
      wrapper.setProps({ items, value: secondItem.value });

      await nextTick();
      expect(wrapper.find(DropdownButton).props('toggleText')).toEqual(secondItem.name);
    });
  });

  describe('when no item is selected', () => {
    it('displays placeholder text', async () => {
      const placeholder = 'placeholder';

      wrapper.setProps({ placeholder });

      await nextTick();
      expect(wrapper.find(DropdownButton).props('toggleText')).toEqual(placeholder);
    });
  });

  describe('when an item is selected', () => {
    beforeEach(async () => {
      wrapper.setProps({ items });
      await nextTick();
      wrapper.findAll('.js-dropdown-item').at(1).trigger('click');
      await nextTick();
    });

    it('emits input event with selected item', () => {
      expect(wrapper.emitted('input')[0]).toEqual([secondItem.value]);
    });
  });

  describe('when multiple items are selected', () => {
    const value = ['1'];

    beforeEach(async () => {
      wrapper.setProps({ items, multiple: true, value });

      await nextTick();
      wrapper.findAll('.js-dropdown-item').at(0).trigger('click');

      await nextTick();
      wrapper.findAll('.js-dropdown-item').at(1).trigger('click');

      await nextTick();
    });

    it('emits input event with an array of selected items', () => {
      expect(wrapper.emitted('input')[1]).toEqual([[firstItem.value, secondItem.value]]);
    });
  });

  describe('when multiple items can be selected', () => {
    beforeEach(async () => {
      wrapper.setProps({ items, multiple: true, value: firstItem.value });
      await nextTick();
    });

    it('displays a checked GlIcon next to the item', () => {
      expect(wrapper.find(GlIcon).classes()).not.toContain('invisible');
      expect(wrapper.find(GlIcon).props('name')).toBe('mobile-issue-close');
    });
  });

  describe('when multiple values can be selected and initial value is null', () => {
    it('emits input event with an array of a single selected item', async () => {
      wrapper.setProps({ items, multiple: true, value: null });

      await nextTick();
      wrapper.findAll('.js-dropdown-item').at(0).trigger('click');

      expect(wrapper.emitted('input')[0]).toEqual([[firstItem.value]]);
    });
  });

  describe('when an item is selected and has a custom label property', () => {
    it('displays selected item custom label', async () => {
      const labelProperty = 'customLabel';
      const label = 'Name';
      const currentValue = '1';
      const customLabelItems = [{ [labelProperty]: label, value: currentValue }];

      wrapper.setProps({ labelProperty, items: customLabelItems, value: currentValue });

      await nextTick();
      expect(wrapper.find(DropdownButton).props('toggleText')).toEqual(label);
    });
  });

  describe('when loading', () => {
    it('dropdown button isLoading', async () => {
      await wrapper.setProps({ loading: true });
      expect(wrapper.find(DropdownButton).props('isLoading')).toBe(true);
    });
  });

  describe('when loading and loadingText is provided', () => {
    it('uses loading text as toggle button text', async () => {
      const loadingText = 'loading text';

      wrapper.setProps({ loading: true, loadingText });

      await nextTick();
      expect(wrapper.find(DropdownButton).props('toggleText')).toEqual(loadingText);
    });
  });

  describe('when disabled', () => {
    it('dropdown button isDisabled', async () => {
      wrapper.setProps({ disabled: true });

      await nextTick();
      expect(wrapper.find(DropdownButton).props('isDisabled')).toBe(true);
    });
  });

  describe('when disabled and disabledText is provided', () => {
    it('uses disabled text as toggle button text', async () => {
      const disabledText = 'disabled text';

      wrapper.setProps({ disabled: true, disabledText });

      await nextTick();
      expect(wrapper.find(DropdownButton).props('toggleText')).toBe(disabledText);
    });
  });

  describe('when has errors', () => {
    it('sets border-danger class selector to dropdown toggle', async () => {
      wrapper.setProps({ hasErrors: true });

      await nextTick();
      expect(wrapper.find(DropdownButton).classes('border-danger')).toBe(true);
    });
  });

  describe('when has errors and an error message', () => {
    it('displays error message', async () => {
      const errorMessage = 'error message';

      wrapper.setProps({ hasErrors: true, errorMessage });

      await nextTick();
      expect(wrapper.find('.js-eks-dropdown-error-message').text()).toEqual(errorMessage);
    });
  });

  describe('when no results are available', () => {
    it('displays empty text', async () => {
      const emptyText = 'error message';

      wrapper.setProps({ items: [], emptyText });

      await nextTick();
      expect(wrapper.find('.js-empty-text').text()).toEqual(emptyText);
    });
  });

  it('displays search field placeholder', async () => {
    const searchFieldPlaceholder = 'Placeholder';

    wrapper.setProps({ searchFieldPlaceholder });

    await nextTick();
    expect(wrapper.find(DropdownSearchInput).props('placeholderText')).toEqual(
      searchFieldPlaceholder,
    );
  });

  it('it filters results by search query', async () => {
    const searchQuery = secondItem.name;

    wrapper.setProps({ items });
    // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
    // eslint-disable-next-line no-restricted-syntax
    wrapper.setData({ searchQuery });

    await nextTick();
    expect(wrapper.findAll('.js-dropdown-item').length).toEqual(1);
    expect(wrapper.find('.js-dropdown-item').text()).toEqual(secondItem.name);
  });

  it('focuses dropdown search input when dropdown is displayed', async () => {
    const dropdownEl = wrapper.find('.dropdown').element;

    expect(wrapper.find(DropdownSearchInput).props('focused')).toBe(false);

    $(dropdownEl).trigger('shown.bs.dropdown');

    await nextTick();
    expect(wrapper.find(DropdownSearchInput).props('focused')).toBe(true);
  });
});
