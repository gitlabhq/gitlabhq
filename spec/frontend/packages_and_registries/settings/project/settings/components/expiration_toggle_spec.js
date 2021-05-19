import { GlToggle, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { GlFormGroup } from 'jest/registry/shared/stubs';
import component from '~/packages_and_registries/settings/project/components/expiration_toggle.vue';
import {
  ENABLED_TOGGLE_DESCRIPTION,
  DISABLED_TOGGLE_DESCRIPTION,
} from '~/packages_and_registries/settings/project/constants';

describe('ExpirationToggle', () => {
  let wrapper;

  const findToggle = () => wrapper.find(GlToggle);
  const findDescription = () => wrapper.find('[data-testid="description"]');

  const mountComponent = (propsData) => {
    wrapper = shallowMount(component, {
      stubs: {
        GlFormGroup,
        GlSprintf,
      },
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('structure', () => {
    it('has a toggle component', () => {
      mountComponent();

      expect(findToggle().props('label')).toBe(component.i18n.toggleLabel);
    });

    it('has a description', () => {
      mountComponent();

      expect(findDescription().exists()).toBe(true);
    });
  });

  describe('model', () => {
    it('assigns the right props to the toggle component', () => {
      mountComponent({ value: true, disabled: true });

      expect(findToggle().props()).toMatchObject({
        value: true,
        disabled: true,
      });
    });

    it('emits input event when toggle is updated', () => {
      mountComponent();

      findToggle().vm.$emit('change', false);

      expect(wrapper.emitted('input')).toEqual([[false]]);
    });
  });

  describe('toggle description', () => {
    it('says enabled when the toggle is on', () => {
      mountComponent({ value: true });

      expect(findDescription().text()).toMatchInterpolatedText(ENABLED_TOGGLE_DESCRIPTION);
    });

    it('says disabled when the toggle is off', () => {
      mountComponent({ value: false });

      expect(findDescription().text()).toMatchInterpolatedText(DISABLED_TOGGLE_DESCRIPTION);
    });
  });
});
