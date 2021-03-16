import $ from 'jquery';
import waitForPromises from 'helpers/wait_for_promises';
import WebAuthnRegister from '~/authentication/webauthn/register';
import MockWebAuthnDevice from './mock_webauthn_device';
import { useMockNavigatorCredentials } from './util';

describe('WebAuthnRegister', () => {
  useMockNavigatorCredentials();

  const mockResponse = {
    type: 'public-key',
    id: '',
    rawId: '',
    response: {
      clientDataJSON: '',
      attestationObject: '',
    },
    getClientExtensionResults: () => {},
  };
  let webAuthnDevice;
  let container;
  let component;

  beforeEach(() => {
    loadFixtures('webauthn/register.html');
    webAuthnDevice = new MockWebAuthnDevice();
    container = $('#js-register-token-2fa');
    component = new WebAuthnRegister(container, {
      options: {
        rp: '',
        user: {
          id: '',
          name: '',
          displayName: '',
        },
        challenge: '',
        pubKeyCredParams: '',
      },
    });
    component.start();
  });

  const findSetupButton = () => container.find('#js-setup-token-2fa-device');
  const findMessage = () => container.find('p');
  const findDeviceResponse = () => container.find('#js-device-response');
  const findRetryButton = () => container.find('#js-token-2fa-try-again');

  it('shows setup button', () => {
    expect(findSetupButton().text()).toBe('Set up new device');
  });

  describe('when unsupported', () => {
    const { location, PublicKeyCredential } = window;

    beforeEach(() => {
      delete window.location;
      delete window.credentials;
      window.location = {};
      window.PublicKeyCredential = undefined;
    });

    afterEach(() => {
      window.location = location;
      window.PublicKeyCredential = PublicKeyCredential;
    });

    it.each`
      httpsEnabled | expectedText
      ${false}     | ${'WebAuthn only works with HTTPS-enabled websites'}
      ${true}      | ${'Please use a supported browser, e.g. Chrome (67+) or Firefox'}
    `('when https is $httpsEnabled', ({ httpsEnabled, expectedText }) => {
      window.location.protocol = httpsEnabled ? 'https:' : 'http:';
      component.start();

      expect(findMessage().text()).toContain(expectedText);
    });
  });

  describe('when setup', () => {
    beforeEach(() => {
      findSetupButton().trigger('click');
    });

    it('shows in progress message', () => {
      expect(findMessage().text()).toContain('Trying to communicate with your device');
    });

    it('registers device', () => {
      webAuthnDevice.respondToRegisterRequest(mockResponse);

      return waitForPromises().then(() => {
        expect(findMessage().text()).toContain('Your device was successfully set up!');
        expect(findDeviceResponse().val()).toBe(JSON.stringify(mockResponse));
      });
    });

    it.each`
      errorName              | expectedText
      ${'NotSupportedError'} | ${'Your device is not compatible with GitLab'}
      ${'NotAllowedError'}   | ${'There was a problem communicating with your device'}
    `('when fails with $errorName', ({ errorName, expectedText }) => {
      webAuthnDevice.rejectRegisterRequest(new DOMException('', errorName));

      return waitForPromises().then(() => {
        expect(findMessage().text()).toContain(expectedText);
        expect(findRetryButton().length).toBe(1);
      });
    });

    it('can retry', () => {
      webAuthnDevice.respondToRegisterRequest({
        errorCode: 'error!',
      });

      return waitForPromises()
        .then(() => {
          findRetryButton().click();

          expect(findMessage().text()).toContain('Trying to communicate with your device');

          webAuthnDevice.respondToRegisterRequest(mockResponse);
          return waitForPromises();
        })
        .then(() => {
          expect(findMessage().text()).toContain('Your device was successfully set up!');
          expect(findDeviceResponse().val()).toBe(JSON.stringify(mockResponse));
        });
    });
  });
});
