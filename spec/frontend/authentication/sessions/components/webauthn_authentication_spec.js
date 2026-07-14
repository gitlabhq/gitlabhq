import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WebAuthnAuthentication from '~/authentication/sessions/components/webauthn_authentication.vue';
import VerificationDivider from '~/authentication/sessions/components/verification_divider.vue';
import { convertGetResponse } from '~/authentication/webauthn/util';
import { createAlert } from '~/alert';
import MockWebAuthnDevice from '../../webauthn/mock_webauthn_device';
import { useMockNavigatorCredentials } from '../../webauthn/util';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));
jest.mock('~/alert');

const mockResponse = {
  type: 'public-key',
  id: '',
  rawId: '',
  response: { clientDataJSON: '', authenticatorData: '', signature: '', userHandle: '' },
  getClientExtensionResults: () => {},
};

const defaultProps = {
  path: '/users/sign_in',
  rememberMe: '1',
  rememberMeEnabled: true,
  totpEnabled: true,
  // Valid base64 ("YQ==" = base64("a")) so convertGetParams/base64ToBuffer succeed.
  webauthnParams: {
    challenge: 'YQ==',
    timeout: 120000,
    allowCredentials: [{ type: 'public-key', id: 'YQ==' }],
    userVerification: 'discouraged',
  },
};

describe('WebAuthnAuthentication', () => {
  useMockNavigatorCredentials();

  let wrapper;
  let webAuthnDevice;
  let submitSpy;
  let alertDismiss;

  const createComponent = (props = {}) => {
    wrapper = mountExtended(WebAuthnAuthentication, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findInProgress = () => wrapper.findByTestId('webauthn-in-progress');
  const findForm = () => wrapper.find('form');
  const findTryAgainButton = () => wrapper.findByTestId('try-again-button');
  const findAuthenticatorAppButton = () => wrapper.findByTestId('authenticator-app-button');
  const findRecoveryButton = () => wrapper.findByTestId('recovery-button');
  const findDeviceResponseInput = () => wrapper.find('input[name="user[device_response]"]');
  const findRememberMeInput = () => wrapper.find('input[name="user[remember_me]"]');
  const findCsrfInput = () => wrapper.find('input[name="authenticity_token"]');
  const findMethodInput = () => wrapper.find('input[name="two_factor_method"]');

  beforeEach(() => {
    webAuthnDevice = new MockWebAuthnDevice();
    submitSpy = jest.spyOn(HTMLFormElement.prototype, 'submit').mockImplementation();
    alertDismiss = jest.fn();
    createAlert.mockReturnValue({ dismiss: alertDismiss });
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('on mount', () => {
    it('shows the heading and description', () => {
      createComponent();

      expect(wrapper.text()).toContain('Verify with security device');
      expect(wrapper.text()).toContain(
        'Follow the instructions in your browser or password manager to authenticate with a passkey, laptop, phone, or authenticator like a YubiKey. Insert a physical key, if you have any.',
      );
    });

    it('auto-triggers authentication and shows the in-progress message', async () => {
      createComponent();
      await nextTick();

      expect(findInProgress().exists()).toBe(true);
    });

    it('disables the "Try again" button while authentication is in progress', async () => {
      createComponent();
      await nextTick();

      expect(findTryAgainButton().props('disabled')).toBe(true);
    });

    it('renders the hidden form with the csrf and remember-me inputs', () => {
      createComponent();

      expect(findForm().classes()).toContain('gl-hidden');
      expect(findCsrfInput().attributes('value')).toBe('mock-csrf-token');
      expect(findRememberMeInput().attributes('value')).toBe(defaultProps.rememberMe);
    });

    it('submits webauthn as the two_factor_method hint', () => {
      createComponent();

      expect(findMethodInput().attributes('value')).toBe('webauthn');
    });

    it('omits the remember-me input when rememberMeEnabled is false', () => {
      createComponent({ rememberMeEnabled: false });

      expect(findRememberMeInput().exists()).toBe(false);
    });
  });

  describe('successful authentication', () => {
    beforeEach(() => {
      createComponent();
      webAuthnDevice.respondToAuthenticateRequest(mockResponse);
      return waitForPromises();
    });

    it('stores the converted device response and submits the form', () => {
      expect(findDeviceResponseInput().attributes('value')).toBe(
        JSON.stringify(convertGetResponse(mockResponse)),
      );
      expect(submitSpy).toHaveBeenCalled();
    });
  });

  describe('failed authentication', () => {
    beforeEach(() => {
      createComponent();
      webAuthnDevice.rejectAuthenticateRequest(new DOMException());
      return waitForPromises();
    });

    it('shows an alert error and does not submit', () => {
      expect(submitSpy).not.toHaveBeenCalled();
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to connect to your device. Try again. (Error)',
        preservePrevious: true,
      });
    });

    it('dismisses the previous alert and re-invokes authentication when "Try again" is clicked', async () => {
      await findTryAgainButton().vm.$emit('click');
      webAuthnDevice.respondToAuthenticateRequest(mockResponse);
      await waitForPromises();

      expect(alertDismiss).toHaveBeenCalled();
      expect(submitSpy).toHaveBeenCalled();
    });
  });

  describe('aborted on unmount', () => {
    it('does not surface an alert for a get() we aborted ourselves', async () => {
      createComponent();
      // Destroy aborts the in-flight get(); its rejection must not leave a stray alert.
      wrapper.destroy();
      webAuthnDevice.rejectAuthenticateRequest(new DOMException('aborted', 'AbortError'));
      await waitForPromises();

      expect(createAlert).not.toHaveBeenCalled();
    });
  });

  describe('alternate-method buttons', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits switch-method "totp" from the authenticator app button', () => {
      findAuthenticatorAppButton().vm.$emit('click');

      expect(wrapper.emitted('switch-method')).toEqual([['totp']]);
    });

    it('emits switch-method "recovery" from the recovery button', () => {
      findRecoveryButton().vm.$emit('click');

      expect(wrapper.emitted('switch-method')).toEqual([['recovery']]);
    });
  });

  describe('when totpEnabled is false', () => {
    beforeEach(() => {
      createComponent({ totpEnabled: false });
    });

    it('hides the authenticator app button and divider', () => {
      expect(findAuthenticatorAppButton().exists()).toBe(false);
      expect(wrapper.findComponent(VerificationDivider).exists()).toBe(false);
    });

    it('still renders the recovery button', () => {
      expect(findRecoveryButton().exists()).toBe(true);
    });
  });

  describe('when WebAuthn is unsupported', () => {
    beforeEach(() => {
      navigator.credentials.get = null;
      createComponent();
    });

    it('emits webauthn-not-supported and does not call get', () => {
      expect(wrapper.emitted('webauthn-not-supported')).toHaveLength(1);
    });
  });
});
