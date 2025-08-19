import htmlWebauthnAuthenticate from 'test_fixtures/webauthn/authenticate.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import WebAuthnAuthenticate from '~/authentication/webauthn/components/authenticate.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import MockWebAuthnDevice from '../mock_webauthn_device';
import { useMockNavigatorCredentials } from '../util';

let wrapper;

const mockResponse = {
  type: 'public-key',
  id: '',
  rawId: '',
  response: { clientDataJSON: '', authenticatorData: '', signature: '', userHandle: '' },
  getClientExtensionResults: () => {},
};

const createComponent = () => {
  wrapper = mountExtended(WebAuthnAuthenticate, {
    propsData: {
      webauthnParams:
        // we need some valid base64 for base64ToBuffer
        // so we use "YQ==" = base64("a")
        {
          challenge: 'YQ==',
          timeout: 120000,
          allowCredentials: [
            { type: 'public-key', id: 'YQ==' },
            { type: 'public-key', id: 'YQ==' },
          ],
          userVerification: 'discouraged',
        },
      targetPath: '/webauthn',
      renderRememberMe: true,
      rememberMe: 'Remember me',
    },
  });
};

describe('WebAuthnAuthenticate', () => {
  useMockNavigatorCredentials();

  let webAuthnDevice;
  let submitSpy;

  const findMessage = () => wrapper.find('#js-authenticate-token-2fa-error p');
  const findRetryButton = () => wrapper.find('#js-token-2fa-try-again');
  const findFallbackElement = () => document.querySelector('.js-2fa-form');
  const findInProgress = () => wrapper.find('p');
  const findAuthenticated = () => wrapper.find('#js-authenticate-token-2fa-authenticated p');

  const expectAuthenticated = () => {
    expect(findAuthenticated().text()).toMatchInterpolatedText(
      'We heard back from your device. You have been authenticated.',
    );
    expect(wrapper.vm.deviceResponse).toBe(JSON.stringify(mockResponse));
    expect(submitSpy).toHaveBeenCalled();
  };

  beforeEach(() => {
    setHTMLFixture(htmlWebauthnAuthenticate);
    webAuthnDevice = new MockWebAuthnDevice();
    submitSpy = jest.spyOn(HTMLFormElement.prototype, 'submit');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('with webauthn unavailable', () => {
    let oldGetCredentials;

    beforeEach(() => {
      oldGetCredentials = window.navigator.credentials.get;
      window.navigator.credentials.get = null;

      createComponent();
    });

    afterEach(() => {
      window.navigator.credentials.get = oldGetCredentials;
    });

    it('falls back to normal 2fa', () => {
      expect(wrapper.findComponent(WebAuthnAuthenticate).isVisible()).toBe(false);
      expect(findFallbackElement()).not.toHaveClass('hidden');
    });
  });

  describe('with webauthn available', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows in progress', () => {
      const inProgressMessage = findInProgress();

      expect(inProgressMessage.text()).toMatchInterpolatedText(
        "Trying to communicate with your device. Plug it in (if you haven't already) and press the button on the device now.",
      );
    });

    it('allows authenticating via a WebAuthn device', async () => {
      webAuthnDevice.respondToAuthenticateRequest(mockResponse);

      await waitForPromises();
      expectAuthenticated();
    });

    describe('errors', () => {
      beforeEach(() => {
        webAuthnDevice.rejectAuthenticateRequest(new DOMException());

        return waitForPromises();
      });

      it('displays an error message', () => {
        expect(submitSpy).not.toHaveBeenCalled();
        expect(findMessage().text()).toMatchInterpolatedText(
          'There was a problem communicating with your device. (Error)',
        );
      });

      it('allows retrying authentication after an error', async () => {
        findRetryButton().trigger('click');
        webAuthnDevice.respondToAuthenticateRequest(mockResponse);

        await waitForPromises();
        expectAuthenticated();
      });
    });
  });
});
