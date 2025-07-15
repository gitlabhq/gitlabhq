import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import StatusDropdown from '~/sidebar/components/status/status_dropdown.vue';
import { statusDropdownOptions } from '~/sidebar/constants';

describe('SubscriptionsDropdown component', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findAllDropdownItems = () => wrapper.findAllComponents(GlListboxItem);
  const findHiddenInput = () => wrapper.find('input');

  function createComponent() {
    wrapper = shallowMount(StatusDropdown, {
      stubs: {
        GlCollapsibleListbox,
        GlListboxItem,
      },
    });
  }

  describe('with no value selected', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders default text', () => {
      expect(findDropdown().props('toggleText')).toBe('Select state');
    });

    it('renders dropdown items with `isSelected` prop set to `false`', () => {
      const dropdownItems = findAllDropdownItems();

      expect(dropdownItems.at(0).props('isSelected')).toBe(false);
      expect(dropdownItems.at(1).props('isSelected')).toBe(false);
    });
  });

  describe('when selecting a value', () => {
    const optionToSelect = statusDropdownOptions[0];

    beforeEach(() => {
      createComponent();
      findDropdown().vm.$emit('select', optionToSelect.value);
    });

    it('updates value of the hidden input', () => {
      expect(findHiddenInput().attributes('value')).toBe(optionToSelect.value);
    });

    it('updates the dropdown text prop', () => {
      expect(findDropdown().props('toggleText')).toBe(optionToSelect.text);
    });

    it('sets dropdown item `isSelected` prop to `true`', () => {
      const dropdownItems = findAllDropdownItems();

      expect(dropdownItems.at(0).props('isSelected')).toBe(true);
      expect(dropdownItems.at(1).props('isSelected')).toBe(false);
    });
  });

  describe('when reset is triggered', () => {
    beforeEach(() => {
      createComponent();
      findDropdown().vm.$emit('select', statusDropdownOptions[0].value);
    });

    it('clears dropdown selection', async () => {
      findDropdown().vm.$emit('reset');
      await nextTick();
      const dropdownItems = findAllDropdownItems();

      expect(dropdownItems.at(0).props('isSelected')).toBe(false);
      expect(dropdownItems.at(1).props('isSelected')).toBe(false);
      expect(findDropdown().props('toggleText')).toBe('Select state');
    });
  });
});
