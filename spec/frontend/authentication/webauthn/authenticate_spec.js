import $ from 'jquery';
import waitForPromises from 'helpers/wait_for_promises';
import WebAuthnAuthenticate from '~/authentication/webauthn/authenticate';
import MockWebAuthnDevice from './mock_webauthn_device';
import { useMockNavigatorCredentials } from './util';

const mockResponse = {
  type: 'public-key',
  id: '',
  rawId: '',
  response: { clientDataJSON: '', authenticatorData: '', signature: '', userHandle: '' },
  getClientExtensionResults: () => {},
};

describe('WebAuthnAuthenticate', () => {
  useMockNavigatorCredentials();

  let fallbackElement;
  let webAuthnDevice;
  let container;
  let component;
  let submitSpy;

  const findDeviceResponseInput = () => container[0].querySelector('#js-device-response');
  const findDeviceResponseInputValue = () => findDeviceResponseInput().value;
  const findMessage = () => container[0].querySelector('p');
  const findRetryButton = () => container[0].querySelector('#js-token-2fa-try-again');
  const expectAuthenticated = () => {
    expect(container.text()).toMatchInterpolatedText(
      'We heard back from your device. You have been authenticated.',
    );
    expect(findDeviceResponseInputValue()).toBe(JSON.stringify(mockResponse));
    expect(submitSpy).toHaveBeenCalled();
  };

  beforeEach(() => {
    loadFixtures('webauthn/authenticate.html');
    fallbackElement = document.createElement('div');
    fallbackElement.classList.add('js-2fa-form');
    webAuthnDevice = new MockWebAuthnDevice();
    container = $('#js-authenticate-token-2fa');
    component = new WebAuthnAuthenticate(
      container,
      '#js-login-token-2fa-form',
      {
        options:
          // we need some valid base64 for base64ToBuffer
          // so we use "YQ==" = base64("a")
          JSON.stringify({
            challenge: 'YQ==',
            timeout: 120000,
            allowCredentials: [
              { type: 'public-key', id: 'YQ==' },
              { type: 'public-key', id: 'YQ==' },
            ],
            userVerification: 'discouraged',
          }),
      },
      document.querySelector('#js-login-2fa-device'),
      fallbackElement,
    );
    submitSpy = jest.spyOn(HTMLFormElement.prototype, 'submit');
  });

  describe('with webauthn unavailable', () => {
    let oldGetCredentials;

    beforeEach(() => {
      oldGetCredentials = window.navigator.credentials.get;
      window.navigator.credentials.get = null;
    });

    afterEach(() => {
      window.navigator.credentials.get = oldGetCredentials;
    });

    it('falls back to normal 2fa', () => {
      component.start();

      expect(container.html()).toBe('');
      expect(container[0]).toHaveClass('hidden');
      expect(fallbackElement).not.toHaveClass('hidden');
    });
  });

  describe('with webauthn available', () => {
    beforeEach(() => {
      component.start();
    });

    it('shows in progress', () => {
      const inProgressMessage = container.find('p');

      expect(inProgressMessage.text()).toMatchInterpolatedText(
        "Trying to communicate with your device. Plug it in (if you haven't already) and press the button on the device now.",
      );
    });

    it('allows authenticating via a WebAuthn device', () => {
      webAuthnDevice.respondToAuthenticateRequest(mockResponse);

      return waitForPromises().then(() => {
        expectAuthenticated();
      });
    });

    describe('errors', () => {
      beforeEach(() => {
        webAuthnDevice.rejectAuthenticateRequest(new DOMException());

        return waitForPromises();
      });

      it('displays an error message', () => {
        expect(submitSpy).not.toHaveBeenCalled();
        expect(findMessage().textContent).toMatchInterpolatedText(
          'There was a problem communicating with your device. (Error)',
        );
      });

      it('allows retrying authentication after an error', () => {
        findRetryButton().click();
        webAuthnDevice.respondToAuthenticateRequest(mockResponse);

        return waitForPromises().then(() => {
          expectAuthenticated();
        });
      });
    });
  });
});
