import { shallowMount } from '@vue/test-utils';
import { GlFormInput } from '@gitlab/ui';
import { GlFormGroup } from 'jest/registry/shared/stubs';
import component from '~/registry/settings/components/expiration_run_text.vue';
import { NEXT_CLEANUP_LABEL, NOT_SCHEDULED_POLICY_TEXT } from '~/registry/settings/constants';

describe('ExpirationToggle', () => {
  let wrapper;
  const value = 'foo';

  const findInput = () => wrapper.find(GlFormInput);
  const findFormGroup = () => wrapper.find(GlFormGroup);

  const mountComponent = propsData => {
    wrapper = shallowMount(component, {
      stubs: {
        GlFormGroup,
      },
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('structure', () => {
    it('has an input component', () => {
      mountComponent();
      expect(findInput().exists()).toBe(true);
    });
  });

  describe('model', () => {
    it('assigns the right props to the input component', () => {
      mountComponent({ value, disabled: true });

      expect(findInput().attributes()).toMatchObject({
        value,
      });
    });

    it('assigns the right props to the form-group component', () => {
      mountComponent();

      expect(findFormGroup().attributes()).toMatchObject({
        label: NEXT_CLEANUP_LABEL,
      });
    });
  });

  describe('formattedValue', () => {
    it('displays the values when it exists', () => {
      mountComponent({ value });

      expect(findInput().attributes('value')).toBe(value);
    });

    it('displays a placeholder when no value is present', () => {
      mountComponent();

      expect(findInput().attributes('value')).toBe(NOT_SCHEDULED_POLICY_TEXT);
    });
  });
});
