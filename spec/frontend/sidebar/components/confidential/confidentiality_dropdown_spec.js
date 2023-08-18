import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import ConfidentialityDropdown from '~/sidebar/components/confidential/confidentiality_dropdown.vue';

describe('ConfidentialityDropdown component', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findHiddenInput = () => wrapper.find('input');

  function createComponent() {
    wrapper = shallowMount(ConfidentialityDropdown, {
      stubs: {
        GlCollapsibleListbox,
      },
    });
  }

  describe('with no value selected', () => {
    beforeEach(() => {
      createComponent();
    });

    it('hidden input value is undefined', () => {
      expect(findHiddenInput().attributes('value')).toBeUndefined();
    });

    it('renders default text', () => {
      expect(findDropdown().props('toggleText')).toBe('Select confidentiality');
    });
  });

  describe('when selecting a value', () => {
    const optionToSelect = { text: 'Not confidential', value: 'false' };

    beforeEach(() => {
      createComponent();
      findDropdown().vm.$emit('select', optionToSelect.value);
    });

    it('updates value of the hidden input', () => {
      expect(findHiddenInput().attributes('value')).toBe(optionToSelect.value);
    });
  });

  describe('when reset is triggered', () => {
    beforeEach(() => {
      createComponent();
      findDropdown().vm.$emit('select', 'true');
    });

    it('clears dropdown selection', async () => {
      expect(findDropdown().props('toggleText')).not.toBe('Select confidentiality');

      findDropdown().vm.$emit('reset');
      await nextTick();

      expect(findDropdown().props('toggleText')).toBe('Select confidentiality');
    });
  });
});
