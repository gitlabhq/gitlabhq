import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import SubscriptionsDropdown from '~/sidebar/components/subscriptions/subscriptions_dropdown.vue';
import { subscriptionsDropdownOptions } from '~/sidebar/constants';

describe('SubscriptionsDropdown component', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findHiddenInput = () => wrapper.find('input');

  function createComponent() {
    wrapper = shallowMount(SubscriptionsDropdown);
  }

  describe('with no value selected', () => {
    beforeEach(() => {
      createComponent();
    });

    it('hidden input value is undefined', () => {
      expect(findHiddenInput().attributes('value')).toBeUndefined();
    });

    it('renders default text', () => {
      expect(findDropdown().props('text')).toBe(SubscriptionsDropdown.i18n.defaultDropdownText);
    });

    it('renders dropdown items with `is-checked` prop set to `false`', () => {
      const dropdownItems = findAllDropdownItems();

      expect(dropdownItems.at(0).props('isChecked')).toBe(false);
      expect(dropdownItems.at(1).props('isChecked')).toBe(false);
    });
  });

  describe('when selecting a value', () => {
    beforeEach(() => {
      createComponent();
      findAllDropdownItems().at(0).vm.$emit('click');
    });

    it('updates value of the hidden input', () => {
      expect(findHiddenInput().attributes('value')).toBe(subscriptionsDropdownOptions[0].value);
    });

    it('updates the dropdown text prop', () => {
      expect(findDropdown().props('text')).toBe(subscriptionsDropdownOptions[0].text);
    });

    it('sets dropdown item `is-checked` prop to `true`', () => {
      const dropdownItems = findAllDropdownItems();

      expect(dropdownItems.at(0).props('isChecked')).toBe(true);
      expect(dropdownItems.at(1).props('isChecked')).toBe(false);
    });

    describe('when selecting the value that is already selected', () => {
      it('clears dropdown selection', async () => {
        findAllDropdownItems().at(0).vm.$emit('click');
        await nextTick();
        const dropdownItems = findAllDropdownItems();

        expect(dropdownItems.at(0).props('isChecked')).toBe(false);
        expect(dropdownItems.at(1).props('isChecked')).toBe(false);
        expect(findDropdown().props('text')).toBe(SubscriptionsDropdown.i18n.defaultDropdownText);
      });
    });
  });
});
