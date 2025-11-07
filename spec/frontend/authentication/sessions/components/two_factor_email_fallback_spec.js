import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TwoFactorEmailFallback from '~/sessions/new/components/two_factor_email_fallback.vue';
import EmailVerification from '~/sessions/new/components/email_verification.vue';
import EmailOtpFallbackFooter from '~/sessions/new/components/email_otp_fallback_footer.vue';
import { createAlert } from '~/alert';

jest.mock('~/alert');

describe('TwoFactorEmailFallback', () => {
  let wrapper;

  const defaultProps = {
    sendEmailOtpPath: '/users/fallback_to_email_otp',
    username: 'testuser',
    emailVerificationData: {
      username: 'testuser',
      obfuscatedEmail: 't***@example.com',
      verifyPath: '/users/sign_in',
      resendPath: '/users/resend_verification_code',
      skipPath: null,
    },
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(TwoFactorEmailFallback, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findEmailVerification = () => wrapper.findComponent(EmailVerification);
  const findEmailOtpFallbackFooter = () => wrapper.findComponent(EmailOtpFallbackFooter);

  beforeEach(() => {
    // Set up DOM element for 2FA form
    document.body.innerHTML = '<div class="js-2fa-form"></div>';
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  describe('initial state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows footer and does not show email verification', () => {
      expect(findEmailOtpFallbackFooter().exists()).toBe(true);
      expect(findEmailVerification().exists()).toBe(false);
    });

    it('passes correct props to footer', () => {
      const footer = findEmailOtpFallbackFooter();

      expect(footer.props()).toMatchObject({
        sendEmailOtpPath: '/users/fallback_to_email_otp',
        username: 'testuser',
      });
    });
  });

  describe('when showEmailVerification is true', () => {
    beforeEach(() => {
      createComponent();
      wrapper.vm.showEmailVerification = true;
    });

    it('hides footer and shows email verification', async () => {
      await nextTick();

      expect(findEmailOtpFallbackFooter().exists()).toBe(false);
      expect(findEmailVerification().exists()).toBe(true);
    });

    it('passes email verification data to component', async () => {
      await nextTick();
      const emailVerification = findEmailVerification();

      expect(emailVerification.props()).toMatchObject(defaultProps.emailVerificationData);
    });
  });

  describe('when emailVerificationData is null', () => {
    beforeEach(() => {
      createComponent({ emailVerificationData: null });
    });

    it('does not show email verification component', async () => {
      await nextTick();

      expect(findEmailVerification().exists()).toBe(false);
      expect(findEmailOtpFallbackFooter().exists()).toBe(false);
    });
  });

  describe('footer events', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows email verification when success event is emitted from footer', async () => {
      const footer = findEmailOtpFallbackFooter();

      footer.vm.$emit('success');
      await waitForPromises();

      expect(wrapper.vm.showEmailVerification).toBe(true);

      await nextTick();
      expect(findEmailVerification().exists()).toBe(true);
      expect(findEmailOtpFallbackFooter().exists()).toBe(false);
    });

    it('creates alert when error event is emitted from footer', async () => {
      const footer = findEmailOtpFallbackFooter();

      footer.vm.$emit('error', {
        message: 'Failed to send email OTP',
        name: 'NetworkError',
      });
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to send email OTP',
        variant: 'danger',
      });
    });
  });
});
