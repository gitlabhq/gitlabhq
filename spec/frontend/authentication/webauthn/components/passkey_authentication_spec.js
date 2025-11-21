import { GlLoadingIcon } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import PasskeyAuthentication from '~/authentication/webauthn/components/passkey_authentication.vue';
import MockWebAuthnDevice from '../mock_webauthn_device';
import { useMockNavigatorCredentials } from '../util';

jest.mock('~/alert');
jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

let wrapper;

const mockResponse = {
  type: 'public-key',
  id: '',
  rawId: '',
  response: { clientDataJSON: '', authenticatorData: '', signature: '', userHandle: '' },
  getClientExtensionResults: () => {},
};

const createComponent = (propsData = {}) => {
  wrapper = mountExtended(PasskeyAuthentication, {
    propsData: {
      path: '/users/passkeys/sign_in',
      rememberMe: '1',
      signInPath: '/',
      webauthnParams:
        // we need some valid base64 for base64ToBuffer
        // so we use "YQ==" = base64("a")
        {
          challenge: 'YQ==',
          timeout: 120000,
          allowCredentials: [],
          userVerification: 'required',
        },
      ...propsData,
    },
  });
};

describe('PasskeyAuthentication', () => {
  useMockNavigatorCredentials();

  let webAuthnDevice;
  let submitSpy;

  const findBackButton = () => wrapper.findByTestId('passkey-authentication-back');
  const findPending = () => wrapper.findByTestId('passkey-authentication-pending');
  const findRetryButton = () => wrapper.findByTestId('passkey-authentication-try-again');
  const findSpinner = () => wrapper.findComponent(GlLoadingIcon);
  const findSuccess = () => wrapper.findByTestId('passkey-authentication-success');

  beforeEach(() => {
    webAuthnDevice = new MockWebAuthnDevice();
    submitSpy = jest.spyOn(HTMLFormElement.prototype, 'submit');
  });

  describe('when passkeys are not supported', () => {
    let oriCredentialsGet;

    beforeEach(() => {
      oriCredentialsGet = window.navigator.credentials.get;
      window.navigator.credentials.get = null;

      createComponent();
    });

    afterEach(() => {
      window.navigator.credentials.get = oriCredentialsGet;
    });

    it('shows an alert', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message:
          'Passkeys only works with HTTPS-enabled websites. Contact your administrator for more details.',
        variant: 'danger',
      });
    });

    it('shows a retry button', () => {
      expect(findRetryButton().props()).toMatchObject({ block: true });
    });

    it('shows a back button', () => {
      expect(findBackButton().props()).toMatchObject({
        block: true,
        href: '/',
        variant: 'confirm',
      });
    });
  });

  describe('when passkeys are supported', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('when in pending state', () => {
      it('shows a message', () => {
        expect(findPending().text()).toMatchInterpolatedText(
          "Trying to communicate with your device. Plug it in (if you haven't already) and press the button on the device now.",
        );
      });

      it('shows a spinner', () => {
        const spinner = findSpinner();
        expect(spinner.props()).toMatchObject({ size: 'md' });
        expect(spinner.attributes('class')).toContain('gl-my-5');
      });
    });

    describe('when in success state', () => {
      beforeEach(() => {
        webAuthnDevice.respondToAuthenticateRequest(mockResponse);
        return waitForPromises();
      });

      it('shows a message', () => {
        expect(findSuccess().text()).toBe('We heard back from your device. Authenticating...');
      });

      it('shows a spinner', () => {
        const spinner = findSpinner();
        expect(spinner.props()).toMatchObject({ size: 'md' });
        expect(spinner.attributes('class')).toContain('gl-my-5');
      });

      it('submits the form', () => {
        expect(
          wrapper
            .find('input[type=hidden][name=authenticity_token][value=mock-csrf-token]')
            .exists(),
        ).toBe(true);
        expect(
          wrapper
            .find(
              `input[type=hidden][name=device_response][value='${JSON.stringify(mockResponse)}']`,
            )
            .exists(),
        ).toBe(true);
        expect(wrapper.find('input[type=hidden][name=remember_me][value="1"]').exists()).toBe(true);
        expect(submitSpy).toHaveBeenCalled();
      });
    });

    describe('when in error state', () => {
      beforeEach(() => {
        webAuthnDevice.rejectAuthenticateRequest(new DOMException());
        return waitForPromises();
      });

      it('shows an alert', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'There was a problem communicating with your device.',
          variant: 'danger',
        });
      });

      it('allows retrying authentication after an error', async () => {
        findRetryButton().trigger('click');
        await waitForPromises();

        expect(findPending().exists()).toBe(true);
      });

      it('shows a back button', () => {
        expect(findBackButton().exists()).toBe(true);
      });
    });
  });
});
