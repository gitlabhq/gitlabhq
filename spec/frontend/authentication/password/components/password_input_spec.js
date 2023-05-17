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
    qaSelector: 'new_user_password_field',
    testid: 'new_user_password',
    autocomplete: 'new-password',
    name: 'new_user',
  };

  const findPasswordInput = () => wrapper.findComponent(GlFormInput);
  const findToggleButton = () => wrapper.findComponent(GlButton);

  const createComponent = () => {
    return shallowMount(PasswordInput, {
      propsData,
    });
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('sets password input attributes correctly', () => {
    expect(findPasswordInput().attributes('id')).toBe(propsData.id);
    expect(findPasswordInput().attributes('autocomplete')).toBe(propsData.autocomplete);
    expect(findPasswordInput().attributes('name')).toBe(propsData.name);
    expect(findPasswordInput().attributes('minlength')).toBe(propsData.minimumPasswordLength);
    expect(findPasswordInput().attributes('data-qa-selector')).toBe(propsData.qaSelector);
    expect(findPasswordInput().attributes('data-testid')).toBe(propsData.testid);
    expect(findPasswordInput().attributes('title')).toBe(propsData.title);
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
