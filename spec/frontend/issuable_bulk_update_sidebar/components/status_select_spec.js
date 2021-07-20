import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import StatusSelect from '~/issuable_bulk_update_sidebar/components/status_select.vue';
import { ISSUE_STATUS_SELECT_OPTIONS } from '~/issuable_bulk_update_sidebar/constants';

describe('StatusSelect', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findHiddenInput = () => wrapper.find('input');

  function createComponent() {
    wrapper = shallowMount(StatusSelect);
  }

  afterEach(() => {
    wrapper.destroy();
  });

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
        ISSUE_STATUS_SELECT_OPTIONS[selectItemAtIndex].value,
      );
    });

    it('updates the dropdown text prop', () => {
      expect(findDropdown().props('text')).toBe(
        ISSUE_STATUS_SELECT_OPTIONS[selectItemAtIndex].text,
      );
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
