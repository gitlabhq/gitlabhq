import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Component from '~/groups/components/visibility_level_dropdown.vue';

describe('Visibility Level Dropdown', () => {
  let wrapper;

  const options = [
    { level: 0, label: 'Private', description: 'Private description' },
    { level: 20, label: 'Public', description: 'Public description' },
  ];
  const defaultLevel = 0;

  const createComponent = (propsData) => {
    wrapper = shallowMount(Component, {
      propsData,
    });
  };

  beforeEach(() => {
    createComponent({
      visibilityLevelOptions: options,
      defaultLevel,
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const hiddenInputValue = () =>
    wrapper.find("input[name='group[visibility_level]']").attributes('value');
  const dropdownText = () => wrapper.find(GlDropdown).props('text');
  const findDropdownItems = () =>
    wrapper.findAll(GlDropdownItem).wrappers.map((option) => ({
      text: option.text(),
      secondaryText: option.props('secondaryText'),
    }));

  describe('Default values', () => {
    it('sets the value of the hidden input to the default value', () => {
      expect(hiddenInputValue()).toBe(options[0].level.toString());
    });

    it('sets the text of the dropdown to the default value', () => {
      expect(dropdownText()).toBe(options[0].label);
    });

    it('shows all dropdown options', () => {
      expect(findDropdownItems()).toEqual(
        options.map(({ label, description }) => ({ text: label, secondaryText: description })),
      );
    });
  });

  describe('Selecting an option', () => {
    beforeEach(() => {
      wrapper.findAll(GlDropdownItem).at(1).vm.$emit('click');
    });

    it('sets the value of the hidden input to the selected value', () => {
      expect(hiddenInputValue()).toBe(options[1].level.toString());
    });

    it('sets the text of the dropdown to the selected value', () => {
      expect(dropdownText()).toBe(options[1].label);
    });
  });
});
