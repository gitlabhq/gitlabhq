import WebAuthnError from '~/authentication/webauthn/error';

describe('WebAuthnError', () => {
  it.each([
    [
      'NotSupportedError',
      'Your device is not compatible with GitLab. Please try another device',
      'authenticate',
    ],
    ['InvalidStateError', 'This device has not been registered with us.', 'authenticate'],
    ['InvalidStateError', 'This device has already been registered with us.', 'register'],
    ['UnknownError', 'There was a problem communicating with your device.', 'register'],
  ])('exception %s will have message %s, flow type: %s', (exception, expectedMessage, flowType) => {
    expect(new WebAuthnError(new DOMException('', exception), flowType).message()).toEqual(
      expectedMessage,
    );
  });

  describe('SecurityError', () => {
    const { location } = window;

    beforeEach(() => {
      delete window.location;
      window.location = {};
    });

    afterEach(() => {
      window.location = location;
    });

    it('returns a descriptive error if https is disabled', () => {
      window.location.protocol = 'http:';

      const expectedMessage =
        'WebAuthn only works with HTTPS-enabled websites. Contact your administrator for more details.';
      expect(
        new WebAuthnError(new DOMException('', 'SecurityError'), 'authenticate').message(),
      ).toEqual(expectedMessage);
    });

    it('returns a generic error if https is enabled', () => {
      window.location.protocol = 'https:';

      const expectedMessage = 'There was a problem communicating with your device.';
      expect(
        new WebAuthnError(new DOMException('', 'SecurityError'), 'authenticate').message(),
      ).toEqual(expectedMessage);
    });
  });
});
