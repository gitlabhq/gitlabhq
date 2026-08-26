import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import PasskeyAuthentication from '~/authentication/sessions/components/passkey_authentication.vue';
import MockWebAuthnDevice from '../../webauthn/mock_webauthn_device';
import { useMockNavigatorCredentials } from '../../webauthn/util';

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

  const findBackButton = () => wrapper.findComponentByTestId('passkey-authentication-back');
  const findIllustration = () => wrapper.find('img');
  const findRetryButton = () => wrapper.findComponentByTestId('passkey-authentication-try-again');
  const findStatus = () => wrapper.findByTestId('passkey-authentication-status');
  const findTitle = () => wrapper.find('h1');
  const findTroubleshootLink = () => wrapper.findByTestId('passkey-authentication-troubleshoot');

  beforeEach(() => {
    webAuthnDevice = new MockWebAuthnDevice();
    submitSpy = jest.spyOn(HTMLFormElement.prototype, 'submit');
  });

  describe('layout', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the illustration as decorative', () => {
      expect(findIllustration().attributes('alt')).toBe('');
    });

    it('renders the title as the page heading', () => {
      expect(findTitle().text()).toBe('Sign in with passkey');
    });

    it('renders the description', () => {
      expect(wrapper.text()).toContain(
        'Follow the instructions on your browser or password manager to continue. Insert your physical key, if you have any.',
      );
    });

    it('links to the passkey troubleshooting documentation', () => {
      expect(findTroubleshootLink().attributes('href')).toBe('/help/auth/passkeys#troubleshooting');
      expect(findTroubleshootLink().text()).toBe('Troubleshoot passkey');
    });

    it('shows a back button', () => {
      expect(findBackButton().props()).toMatchObject({ block: true, href: '/users/sign_in' });
    });
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

    it('shows an enabled retry button', () => {
      expect(findRetryButton().props()).toMatchObject({ block: true, variant: 'confirm' });
      expect(findRetryButton().attributes('aria-disabled')).toBeUndefined();
    });

    it('shows no status message', () => {
      expect(findStatus().text()).toBe('');
    });
  });

  describe('when passkeys are supported', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('when in pending state', () => {
      it('shows a message', () => {
        expect(findStatus().text()).toMatchInterpolatedText(
          "Trying to communicate with your device. Plug it in (if you haven't already) and press the button on the device now.",
        );
      });

      it('keeps the retry button focusable but inert', () => {
        expect(findRetryButton().attributes('aria-disabled')).toBe('true');
        expect(findRetryButton().attributes('disabled')).toBeUndefined();
      });
    });

    describe('when in success state', () => {
      beforeEach(() => {
        webAuthnDevice.respondToAuthenticateRequest(mockResponse);
        return waitForPromises();
      });

      it('shows a message', () => {
        expect(findStatus().text()).toBe('We heard back from your device. Authenticating...');
      });

      it('keeps the retry button inert while the form submits', () => {
        expect(findRetryButton().attributes('aria-disabled')).toBe('true');
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
          message: 'Failed to connect to your device. Try again.',
          variant: 'danger',
        });
      });

      it('shows no status message', () => {
        expect(findStatus().text()).toBe('');
      });

      it('allows retrying authentication after an error', async () => {
        findRetryButton().trigger('click');
        await waitForPromises();

        expect(findStatus().text()).toMatchInterpolatedText(
          "Trying to communicate with your device. Plug it in (if you haven't already) and press the button on the device now.",
        );
      });

      it('shows a back button', () => {
        expect(findBackButton().exists()).toBe(true);
      });
    });
  });
});
