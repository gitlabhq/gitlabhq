import { mountExtended } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import TwoFactorAuthentication from '~/authentication/sessions/components/two_factor_authentication.vue';
import TotpCode from '~/authentication/sessions/components/totp_code.vue';
import RecoveryCode from '~/authentication/sessions/components/recovery_code.vue';
import WebauthnAuthentication from '~/authentication/sessions/components/webauthn_authentication.vue';
import EmailCode from '~/authentication/sessions/components/email_code.vue';
import { useMockNavigatorCredentials } from '../../webauthn/util';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));
// EmailCode auto-sends a code on mount; stub the request so it resolves quietly.
jest.mock('~/lib/utils/axios_utils', () => ({
  __esModule: true,
  default: { post: jest.fn().mockResolvedValue({ data: {} }) },
}));

describe('TwoFactorAuthentication', () => {
  useMockNavigatorCredentials();

  let wrapper;

  // Valid base64 ("YQ==" = base64("a")) so convertGetParams/base64ToBuffer succeed; a
  // webauthn-enabled user always receives these from gon.webauthn in production.
  const webauthnParams = {
    challenge: 'YQ==',
    timeout: 120000,
    allowCredentials: [{ type: 'public-key', id: 'YQ==' }],
    userVerification: 'discouraged',
  };

  const defaultProps = {
    path: '/users/sign_in',
    rememberMe: '1',
    rememberMeEnabled: true,
    webauthnEnabled: false,
    totpEnabled: true,
    webauthnParams,
    emailEnabled: false,
  };

  const emailVerificationData = {
    obfuscatedEmail: 't***@example.com',
    verifyPath: '/users/sign_in',
    resendPath: '/users/resend_verification_code',
    skipPath: null,
    showResendAfter: null,
  };

  const createComponent = (props = {}) => {
    wrapper = mountExtended(TwoFactorAuthentication, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findTotpCode = () => wrapper.findComponent(TotpCode);
  const findRecoveryCode = () => wrapper.findComponent(RecoveryCode);
  const findWebauthnAuthentication = () => wrapper.findComponent(WebauthnAuthentication);
  const findEmailCode = () => wrapper.findComponent(EmailCode);

  beforeEach(() => {
    createComponent();
  });

  it('defaults to rendering TotpCode when webauthn is disabled', () => {
    expect(findTotpCode().exists()).toBe(true);
    expect(findRecoveryCode().exists()).toBe(false);
    expect(findWebauthnAuthentication().exists()).toBe(false);
  });

  it('forwards props to the active child', () => {
    expect(findTotpCode().props()).toMatchObject({
      path: defaultProps.path,
      rememberMe: defaultProps.rememberMe,
      rememberMeEnabled: defaultProps.rememberMeEnabled,
      webauthnEnabled: defaultProps.webauthnEnabled,
    });
  });

  it('renders activeMethod instead of the default when provided', () => {
    createComponent({ activeMethod: 'recovery' });

    expect(findRecoveryCode().exists()).toBe(true);
    expect(findTotpCode().exists()).toBe(false);
  });

  describe('when switch-method "recovery" is emitted', () => {
    beforeEach(async () => {
      await findTotpCode().vm.$emit('switch-method', 'recovery');
    });

    it('shows RecoveryCode and hides TotpCode', () => {
      expect(findRecoveryCode().exists()).toBe(true);
      expect(findTotpCode().exists()).toBe(false);
    });

    it('forwards props to RecoveryCode', () => {
      expect(findRecoveryCode().props()).toMatchObject({
        path: defaultProps.path,
        rememberMe: defaultProps.rememberMe,
        rememberMeEnabled: defaultProps.rememberMeEnabled,
      });
    });
  });

  describe('when webauthnEnabled is true', () => {
    beforeEach(() => {
      createComponent({ webauthnEnabled: true });
    });

    it('defaults to rendering WebauthnAuthentication', () => {
      expect(findWebauthnAuthentication().exists()).toBe(true);
      expect(findTotpCode().exists()).toBe(false);
    });

    it('forwards props to WebauthnAuthentication', () => {
      expect(findWebauthnAuthentication().props()).toMatchObject({
        path: defaultProps.path,
        rememberMe: defaultProps.rememberMe,
        rememberMeEnabled: defaultProps.rememberMeEnabled,
        totpEnabled: defaultProps.totpEnabled,
        webauthnParams,
      });
    });

    it('switches to TotpCode when switch-method "totp" is emitted', async () => {
      await findWebauthnAuthentication().vm.$emit('switch-method', 'totp');

      expect(findTotpCode().exists()).toBe(true);
      expect(findWebauthnAuthentication().exists()).toBe(false);
    });
  });

  describe('deep-link fragment', () => {
    afterEach(() => {
      setWindowLocation('https://gitlab.test/users/sign_in');
    });

    it('appends the address-bar fragment to the active child path', () => {
      setWindowLocation('https://gitlab.test/users/sign_in#L7');
      createComponent();

      expect(findTotpCode().props('path')).toBe(`${defaultProps.path}#L7`);
    });

    it('leaves the path unchanged when there is no fragment', () => {
      createComponent();

      expect(findTotpCode().props('path')).toBe(defaultProps.path);
    });
  });

  describe('webauthn-not-supported fallback', () => {
    it('falls back to TotpCode when totp is enabled', async () => {
      createComponent({ webauthnEnabled: true, totpEnabled: true });

      await findWebauthnAuthentication().vm.$emit('webauthn-not-supported');

      expect(findTotpCode().exists()).toBe(true);
      expect(findWebauthnAuthentication().exists()).toBe(false);
    });

    it('falls back to EmailCode when totp is disabled but email is enabled', async () => {
      createComponent({
        webauthnEnabled: true,
        totpEnabled: false,
        emailEnabled: true,
        emailVerificationData,
        sendEmailOtpPath: '/users/fallback_to_email_otp',
      });

      await findWebauthnAuthentication().vm.$emit('webauthn-not-supported');

      expect(findEmailCode().exists()).toBe(true);
      expect(findWebauthnAuthentication().exists()).toBe(false);
    });

    it('falls back to RecoveryCode when totp and email are disabled', async () => {
      createComponent({ webauthnEnabled: true, totpEnabled: false, emailEnabled: false });

      await findWebauthnAuthentication().vm.$emit('webauthn-not-supported');

      expect(findRecoveryCode().exists()).toBe(true);
      expect(findWebauthnAuthentication().exists()).toBe(false);
    });
  });

  describe('when only email OTP is available', () => {
    beforeEach(() => {
      createComponent({
        webauthnEnabled: false,
        totpEnabled: false,
        emailEnabled: true,
        emailVerificationData,
        sendEmailOtpPath: '/users/fallback_to_email_otp',
      });
    });

    it('defaults to rendering EmailCode', () => {
      expect(findEmailCode().exists()).toBe(true);
      expect(findTotpCode().exists()).toBe(false);
    });

    it('forwards props to EmailCode', () => {
      expect(findEmailCode().props()).toMatchObject({
        sendEmailOtpPath: '/users/fallback_to_email_otp',
        emailVerificationData,
      });
    });
  });
});
