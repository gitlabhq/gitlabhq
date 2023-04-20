import { GlFormInput, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PasswordInput from '~/authentication/password/components/password_input.vue';
import { SHOW_PASSWORD, HIDE_PASSWORD } from '~/authentication/password/constants';

describe('PasswordInput', () => {
  let wrapper;

  const findPasswordInput = () => wrapper.findComponent(GlFormInput);
  const findToggleButton = () => wrapper.findComponent(GlButton);

  const createComponent = () => {
    return shallowMount(PasswordInput, {
      propsData: {
        resourceName: 'new_user',
        minimumPasswordLength: '8',
        qaSelector: 'new_user_password_field',
      },
    });
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('when the show password button is clicked', () => {
    beforeEach(() => {
      findToggleButton().vm.$emit('click');
    });

    it('displays hide password button', () => {
      expect(findPasswordInput().attributes('type')).toBe('text');
      expect(findToggleButton().attributes('icon')).toBe('eye-slash');
      expect(findToggleButton().attributes('aria-label')).toBe(HIDE_PASSWORD);
    });

    describe('when the hide password button is clicked', () => {
      beforeEach(() => {
        findToggleButton().vm.$emit('click');
      });

      it('displays show password button', () => {
        expect(findPasswordInput().attributes('type')).toBe('password');
        expect(findToggleButton().attributes('icon')).toBe('eye');
        expect(findToggleButton().attributes('aria-label')).toBe(SHOW_PASSWORD);
      });
    });
  });
});
