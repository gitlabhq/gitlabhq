import { GlFormInput, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PasswordInput from '~/authentication/password/components/password_input.vue';
import { SHOW_PASSWORD, HIDE_PASSWORD } from '~/authentication/password/constants';

describe('PasswordInput', () => {
  let wrapper;
  const propsData = {
    title: 'This field is required',
    id: 'new_user_password',
    minimumPasswordLength: '8',
    testid: 'new_user_password',
    autocomplete: 'new-password',
    name: 'new_user',
  };

  const findPasswordInput = () => wrapper.findComponent(GlFormInput);
  const findToggleButton = () => wrapper.findComponent(GlButton);

  const createComponent = (props = {}) => {
    return shallowMount(PasswordInput, {
      propsData: {
        ...propsData,
        ...props,
      },
    });
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('sets password input attributes correctly', () => {
    const passwordInput = findPasswordInput();

    expect(passwordInput.attributes('id')).toBe(propsData.id);
    expect(passwordInput.attributes('autocomplete')).toBe(propsData.autocomplete);
    expect(passwordInput.attributes('name')).toBe(propsData.name);
    expect(passwordInput.attributes('minlength')).toBe(propsData.minimumPasswordLength);
    expect(passwordInput.attributes('data-testid')).toBe(propsData.testid);
    expect(passwordInput.attributes('title')).toBe(propsData.title);
    expect(passwordInput.attributes('required')).toBe('true');
  });

  describe('when password input is not required', () => {
    it('does not set required attribute', () => {
      wrapper = createComponent({ required: false });

      expect(findPasswordInput().attributes('required')).toBe(undefined);
    });
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
