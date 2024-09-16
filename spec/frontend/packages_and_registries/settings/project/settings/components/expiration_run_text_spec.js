import { GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { GlFormGroup } from 'jest/packages_and_registries/shared/stubs';
import component from '~/packages_and_registries/settings/project/components/expiration_run_text.vue';
import {
  NEXT_CLEANUP_LABEL,
  NOT_SCHEDULED_POLICY_TEXT,
} from '~/packages_and_registries/settings/project/constants';

describe('ExpirationToggle', () => {
  let wrapper;
  const value = new Date().toISOString();

  const findInput = () => wrapper.findComponent(GlFormInput);
  const findFormGroup = () => wrapper.findComponent(GlFormGroup);

  const mountComponent = (propsData) => {
    wrapper = shallowMount(component, {
      stubs: {
        GlFormGroup,
      },
      propsData,
    });
  };

  describe('structure', () => {
    it('has an input component', () => {
      mountComponent();

      expect(findInput().exists()).toBe(true);
    });
  });

  describe('model', () => {
    it('assigns the right props to the form-group component', () => {
      mountComponent();

      expect(findFormGroup().attributes()).toMatchObject({
        label: NEXT_CLEANUP_LABEL,
      });
    });
  });

  describe('formattedValue', () => {
    it.each`
      valueProp    | enabled  | expected
      ${value}     | ${true}  | ${'July 6, 2020 at 12:00:00 AM GMT'}
      ${value}     | ${false} | ${NOT_SCHEDULED_POLICY_TEXT}
      ${undefined} | ${false} | ${NOT_SCHEDULED_POLICY_TEXT}
      ${undefined} | ${true}  | ${NOT_SCHEDULED_POLICY_TEXT}
    `(
      'when value is $valueProp and enabled is $enabled the input value is $expected',
      ({ valueProp, enabled, expected }) => {
        mountComponent({ value: valueProp, enabled });

        expect(findInput().attributes('value')).toBe(expected);
      },
    );
  });
});
