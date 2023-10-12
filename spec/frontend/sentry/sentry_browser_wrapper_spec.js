import * as Sentry from '~/sentry/sentry_browser_wrapper';

const mockError = new Error('error!');
const mockMsg = 'msg!';

describe('SentryBrowserWrapper', () => {
  afterEach(() => {
    // eslint-disable-next-line no-underscore-dangle
    delete window._Sentry;
  });

  describe('when _Sentry is not defined', () => {
    it('methods fail silently', () => {
      expect(() => {
        Sentry.captureException(mockError);
        Sentry.captureMessage(mockMsg);
      }).not.toThrow();
    });
  });

  describe('when _Sentry is defined', () => {
    let mockCaptureException;
    let mockCaptureMessage;

    beforeEach(() => {
      mockCaptureException = jest.fn();
      mockCaptureMessage = jest.fn();

      // eslint-disable-next-line no-underscore-dangle
      window._Sentry = {
        captureException: mockCaptureException,
        captureMessage: mockCaptureMessage,
      };
    });

    it('captureException is called', () => {
      Sentry.captureException(mockError);

      expect(mockCaptureException).toHaveBeenCalledWith(mockError);
    });

    it('captureMessage is called', () => {
      Sentry.captureMessage(mockMsg);

      expect(mockCaptureMessage).toHaveBeenCalledWith(mockMsg);
    });
  });
});
