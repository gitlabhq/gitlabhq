import { GlLink, GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import EmailOtpFallbackFooter from '~/sessions/new/components/email_otp_fallback_footer.vue';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/lib/utils/axios_utils');

describe('EmailOtpFallbackFooter', () => {
  let wrapper;

  const defaultProps = {
    sendEmailOtpPath: '/users/fallback_to_email_otp',
    username: 'testuser',
  };

  const createComponent = (props = {}) => {
    wrapper = mountExtended(EmailOtpFallbackFooter, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  beforeEach(() => {
    // Set up DOM element for 2FA form
    document.body.innerHTML = '<div class="js-2fa-form"></div>';
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  const findRecoveryCodeLink = () => wrapper.findComponent(GlLink);
  const findEmailOtpButton = () => wrapper.findComponent(GlButton);

  describe('rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the help text', () => {
      expect(wrapper.text()).toContain('Having trouble signing in?');
      expect(wrapper.text()).toContain('Enter recovery code');
      expect(wrapper.text()).toContain('send code to email address');
    });

    it('renders recovery code link with correct href', () => {
      const link = findRecoveryCodeLink();

      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe(
        '/help/user/profile/account/two_factor_authentication#recovery-codes',
      );
      expect(link.attributes('target')).toBe('_blank');
      expect(link.text()).toBe('Enter recovery code');
    });

    it('renders email OTP button', () => {
      const button = findEmailOtpButton();

      expect(button.exists()).toBe(true);
      expect(button.props()).toMatchObject({
        variant: 'link',
        category: 'tertiary',
        loading: false,
        disabled: false,
      });
    });
  });

  describe('loading state', () => {
    beforeEach(() => {
      createComponent();
      axios.post = jest.fn().mockImplementation(
        () => new Promise(() => {}), // Never resolves, keeps loading
      );
    });

    it('sets button to loading state while request is in progress', async () => {
      const button = findEmailOtpButton();

      button.trigger('click');
      await nextTick();

      expect(button.props('loading')).toBe(true);
      expect(button.props('disabled')).toBe(true);
    });
  });

  describe('events', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits success event when email OTP request succeeds', async () => {
      axios.post = jest.fn().mockResolvedValue({ data: { success: true } });
      const button = findEmailOtpButton();

      await button.trigger('click');
      await waitForPromises();

      expect(axios.post).toHaveBeenCalledWith('/users/fallback_to_email_otp', {
        user: { login: 'testuser' },
      });
      expect(wrapper.emitted('success')).toHaveLength(1);
    });

    it('hides 2FA form on success', async () => {
      axios.post = jest.fn().mockResolvedValue({ data: { success: true } });
      const twoFaForm = document.querySelector('.js-2fa-form');
      const button = findEmailOtpButton();

      await button.trigger('click');
      await waitForPromises();

      expect(twoFaForm.classList.contains('hidden')).toBe(true);
    });

    it('emits error event when email OTP request fails', async () => {
      const errorMessage = 'Network error';
      axios.post = jest.fn().mockRejectedValue({ message: errorMessage });
      const button = findEmailOtpButton();

      await button.trigger('click');
      await waitForPromises();

      expect(wrapper.emitted('error')).toHaveLength(1);
      expect(wrapper.emitted('error')[0][0]).toMatchObject({
        message: expect.stringContaining('Failed to send email OTP'),
        name: errorMessage,
      });
    });

    it('sets loading state back to false after error', async () => {
      axios.post = jest.fn().mockRejectedValue({ message: 'Error' });
      const button = findEmailOtpButton();

      await button.trigger('click');
      await waitForPromises();

      expect(button.props('loading')).toBe(false);
      expect(button.props('disabled')).toBe(false);
    });
  });
});
