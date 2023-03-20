import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import StatusDropdown from '~/sidebar/components/status/status_dropdown.vue';
import { statusDropdownOptions } from '~/sidebar/constants';

describe('SubscriptionsDropdown component', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findHiddenInput = () => wrapper.find('input');

  function createComponent() {
    wrapper = shallowMount(StatusDropdown);
  }

  describe('with no value selected', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders default text', () => {
      expect(findDropdown().props('text')).toBe('Select status');
    });

    it('renders dropdown items with `is-checked` prop set to `false`', () => {
      const dropdownItems = findAllDropdownItems();

      expect(dropdownItems.at(0).props('isChecked')).toBe(false);
      expect(dropdownItems.at(1).props('isChecked')).toBe(false);
    });
  });

  describe('when selecting a value', () => {
    const selectItemAtIndex = 0;

    beforeEach(async () => {
      createComponent();
      await findAllDropdownItems().at(selectItemAtIndex).vm.$emit('click');
    });

    it('updates value of the hidden input', () => {
      expect(findHiddenInput().attributes('value')).toBe(
        statusDropdownOptions[selectItemAtIndex].value,
      );
    });

    it('updates the dropdown text prop', () => {
      expect(findDropdown().props('text')).toBe(statusDropdownOptions[selectItemAtIndex].text);
    });

    it('sets dropdown item `is-checked` prop to `true`', () => {
      const dropdownItems = findAllDropdownItems();

      expect(dropdownItems.at(0).props('isChecked')).toBe(true);
      expect(dropdownItems.at(1).props('isChecked')).toBe(false);
    });

    describe('when selecting the value that is already selected', () => {
      it('clears dropdown selection', async () => {
        await findAllDropdownItems().at(selectItemAtIndex).vm.$emit('click');

        const dropdownItems = findAllDropdownItems();

        expect(dropdownItems.at(0).props('isChecked')).toBe(false);
        expect(dropdownItems.at(1).props('isChecked')).toBe(false);
        expect(findDropdown().props('text')).toBe('Select status');
      });
    });
  });
});
