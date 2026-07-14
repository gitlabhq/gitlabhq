import { mountExtended } from 'helpers/vue_test_utils_helper';
import TwoFactorAuthentication from '~/authentication/sessions/components/two_factor_authentication.vue';
import TotpCode from '~/authentication/sessions/components/totp_code.vue';
import RecoveryCode from '~/authentication/sessions/components/recovery_code.vue';
import WebauthnAuthentication from '~/authentication/sessions/components/webauthn_authentication.vue';
import { useMockNavigatorCredentials } from '../../webauthn/util';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

describe('TwoFactorAuthentication', () => {
  useMockNavigatorCredentials();

  let wrapper;

  const defaultProps = {
    path: '/users/sign_in',
    rememberMe: '1',
    rememberMeEnabled: true,
    webauthnEnabled: false,
    totpEnabled: true,
  };

  const createComponent = (props = {}) => {
    wrapper = mountExtended(TwoFactorAuthentication, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findTotpCode = () => wrapper.findComponent(TotpCode);
  const findRecoveryCode = () => wrapper.findComponent(RecoveryCode);
  const findWebauthnAuthentication = () => wrapper.findComponent(WebauthnAuthentication);

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
        webauthnParams: {},
      });
    });

    it('switches to TotpCode when switch-method "totp" is emitted', async () => {
      await findWebauthnAuthentication().vm.$emit('switch-method', 'totp');

      expect(findTotpCode().exists()).toBe(true);
      expect(findWebauthnAuthentication().exists()).toBe(false);
    });
  });

  describe('webauthn-not-supported fallback', () => {
    it('falls back to TotpCode when totp is enabled', async () => {
      createComponent({ webauthnEnabled: true, totpEnabled: true });

      await findWebauthnAuthentication().vm.$emit('webauthn-not-supported');

      expect(findTotpCode().exists()).toBe(true);
      expect(findWebauthnAuthentication().exists()).toBe(false);
    });

    it('falls back to RecoveryCode when totp is disabled', async () => {
      createComponent({ webauthnEnabled: true, totpEnabled: false });

      await findWebauthnAuthentication().vm.$emit('webauthn-not-supported');

      expect(findRecoveryCode().exists()).toBe(true);
      expect(findWebauthnAuthentication().exists()).toBe(false);
    });
  });
});
