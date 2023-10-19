import * as Sentry from '~/sentry/sentry_browser_wrapper';

const mockError = new Error('error!');

describe('SentryBrowserWrapper', () => {
  afterEach(() => {
    // eslint-disable-next-line no-underscore-dangle
    delete window._Sentry;
  });

  describe('when _Sentry is not defined', () => {
    it('methods fail silently', () => {
      expect(() => {
        Sentry.captureException(mockError);
      }).not.toThrow();
    });
  });

  describe('when _Sentry is defined', () => {
    let mockCaptureException;

    beforeEach(() => {
      mockCaptureException = jest.fn();

      // eslint-disable-next-line no-underscore-dangle
      window._Sentry = {
        captureException: mockCaptureException,
      };
    });

    it('captureException is called', () => {
      Sentry.captureException(mockError);

      expect(mockCaptureException).toHaveBeenCalledWith(mockError);
    });
  });
});
