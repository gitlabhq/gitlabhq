import { GlToggle, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { GlFormGroup } from 'jest/packages_and_registries/shared/stubs';
import ExpirationToggle from '~/packages_and_registries/settings/project/components/expiration_toggle.vue';
import {
  ENABLED_TOGGLE_DESCRIPTION,
  DISABLED_TOGGLE_DESCRIPTION,
} from '~/packages_and_registries/settings/project/constants';

describe('ExpirationToggle', () => {
  let wrapper;

  const findToggle = () => wrapper.findComponent(GlToggle);
  const findDescription = () => wrapper.findByTestId('description');

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ExpirationToggle, {
      stubs: {
        GlFormGroup,
        GlSprintf,
      },
      propsData: {
        ...props,
      },
    });
  };

  describe('structure', () => {
    it('has a toggle component', () => {
      createComponent();

      expect(findToggle().props('label')).toBe(ExpirationToggle.i18n.toggleLabel);
    });

    it('has a description', () => {
      createComponent();

      expect(findDescription().exists()).toBe(true);
    });
  });

  describe('model', () => {
    it('assigns the right props to the toggle component', () => {
      createComponent({ value: true, disabled: true });

      expect(findToggle().props()).toMatchObject({
        value: true,
        disabled: true,
      });
    });

    it('emits input event when toggle is updated', () => {
      createComponent();

      findToggle().vm.$emit('change', false);

      expect(wrapper.emitted('input')).toEqual([[false]]);
    });
  });

  describe('toggle description', () => {
    it('says enabled when the toggle is on', () => {
      createComponent({ value: true });

      expect(findDescription().text()).toMatchInterpolatedText(ENABLED_TOGGLE_DESCRIPTION);
    });

    it('says disabled when the toggle is off', () => {
      createComponent({ value: false });

      expect(findDescription().text()).toMatchInterpolatedText(DISABLED_TOGGLE_DESCRIPTION);
    });
  });
});
