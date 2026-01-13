import WebAuthnError from '~/authentication/webauthn/error';
import { WEBAUTHN_AUTHENTICATE, WEBAUTHN_REGISTER } from '~/authentication/webauthn/constants';

describe('WebAuthnError', () => {
  it.each([
    [
      'NotSupportedError',
      'Your device is not compatible with GitLab. Please try another device',
      WEBAUTHN_AUTHENTICATE,
    ],
    ['InvalidStateError', 'This device has not been registered with us.', WEBAUTHN_AUTHENTICATE],
    ['InvalidStateError', 'This device has already been registered with us.', WEBAUTHN_REGISTER],
    ['UnknownError', 'Failed to connect to your device. Try again.', WEBAUTHN_REGISTER],
  ])('exception %s will have message %s, flow type: %s', (exception, expectedMessage, flowType) => {
    expect(new WebAuthnError(new DOMException('', exception), flowType).message()).toEqual(
      expectedMessage,
    );
  });

  describe('SecurityError', () => {
    it('returns a descriptive error if https is disabled', () => {
      Object.defineProperty(window, 'isSecureContext', {
        configurable: true,
        value: false,
      });

      const expectedMessage =
        'WebAuthn only works with HTTPS-enabled websites. Contact your administrator for more details.';
      expect(
        new WebAuthnError(new DOMException('', 'SecurityError'), WEBAUTHN_AUTHENTICATE).message(),
      ).toEqual(expectedMessage);
    });

    it('returns a generic error if https is enabled', () => {
      Object.defineProperty(window, 'isSecureContext', {
        configurable: true,
        value: true,
      });

      const expectedMessage = 'Failed to connect to your device. Try again.';
      expect(
        new WebAuthnError(new DOMException('', 'SecurityError'), WEBAUTHN_AUTHENTICATE).message(),
      ).toEqual(expectedMessage);
    });
  });
});
