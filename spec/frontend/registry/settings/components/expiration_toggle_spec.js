import { shallowMount } from '@vue/test-utils';
import { GlToggle, GlSprintf } from '@gitlab/ui';
import { GlFormGroup } from 'jest/registry/shared/stubs';
import component from '~/registry/settings/components/expiration_toggle.vue';
import {
  ENABLE_TOGGLE_DESCRIPTION,
  ENABLED_TEXT,
  DISABLED_TEXT,
} from '~/registry/settings/constants';

describe('ExpirationToggle', () => {
  let wrapper;

  const findToggle = () => wrapper.find(GlToggle);
  const findDescription = () => wrapper.find('[data-testid="description"]');

  const mountComponent = propsData => {
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

      expect(findToggle().exists()).toBe(true);
    });

    it('has a description', () => {
      mountComponent();

      expect(findDescription().text()).toContain(
        ENABLE_TOGGLE_DESCRIPTION.replace('%{toggleStatus}', ''),
      );
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

      expect(findDescription().text()).toContain(ENABLED_TEXT);
    });

    it('says disabled when the toggle is off', () => {
      mountComponent({ value: false });

      expect(findDescription().text()).toContain(DISABLED_TEXT);
    });
  });
});
