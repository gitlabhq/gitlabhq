import { GlButton } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import SignupSubmitButton from '~/registrations/components/signup_submit_button.vue';

describe('SignupSubmitButton', () => {
  let wrapper;

  const findButton = () => wrapper.findComponent(GlButton);

  const createComponent = (props = {}) => {
    wrapper = mountExtended(SignupSubmitButton, {
      propsData: {
        buttonText: 'Continue',
        ...props,
      },
    });
  };

  it('renders a submit button with the correct text', () => {
    createComponent();

    expect(findButton().text()).toBe('Continue');
  });

  it('renders with variant confirm and block', () => {
    createComponent();

    expect(findButton().props('variant')).toBe('confirm');
    expect(findButton().props('block')).toBe(true);
  });

  it('renders with the correct data-testid', () => {
    createComponent();

    expect(wrapper.findByTestId('new-user-register-button').exists()).toBe(true);
  });

  it('passes the loading prop to GlButton', () => {
    createComponent({ loading: true });

    expect(findButton().props('loading')).toBe(true);
  });

  it('sets data-track-action to register', () => {
    createComponent();

    expect(findButton().attributes('data-track-action')).toBe('register');
  });

  it('passes the track label', () => {
    createComponent({ trackLabel: 'free_registration' });

    expect(findButton().attributes('data-track-label')).toBe('free_registration');
  });
});
