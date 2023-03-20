import setWindowLocation from 'helpers/set_window_location_helper';
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
    ['UnknownError', 'There was a problem communicating with your device.', WEBAUTHN_REGISTER],
  ])('exception %s will have message %s, flow type: %s', (exception, expectedMessage, flowType) => {
    expect(new WebAuthnError(new DOMException('', exception), flowType).message()).toEqual(
      expectedMessage,
    );
  });

  describe('SecurityError', () => {
    it('returns a descriptive error if https is disabled', () => {
      setWindowLocation('http://localhost');

      const expectedMessage =
        'WebAuthn only works with HTTPS-enabled websites. Contact your administrator for more details.';
      expect(
        new WebAuthnError(new DOMException('', 'SecurityError'), WEBAUTHN_AUTHENTICATE).message(),
      ).toEqual(expectedMessage);
    });

    it('returns a generic error if https is enabled', () => {
      setWindowLocation('https://localhost');

      const expectedMessage = 'There was a problem communicating with your device.';
      expect(
        new WebAuthnError(new DOMException('', 'SecurityError'), WEBAUTHN_AUTHENTICATE).message(),
      ).toEqual(expectedMessage);
    });
  });
});
