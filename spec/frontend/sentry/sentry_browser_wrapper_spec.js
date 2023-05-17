import * as Sentry from '~/sentry/sentry_browser_wrapper';

const mockError = new Error('error!');
const mockMsg = 'msg!';
const mockFn = () => {};

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
        Sentry.withScope(mockFn);
      }).not.toThrow();
    });
  });

  describe('when _Sentry is defined', () => {
    let mockCaptureException;
    let mockCaptureMessage;
    let mockWithScope;

    beforeEach(() => {
      mockCaptureException = jest.fn();
      mockCaptureMessage = jest.fn();
      mockWithScope = jest.fn();

      // eslint-disable-next-line no-underscore-dangle
      window._Sentry = {
        captureException: mockCaptureException,
        captureMessage: mockCaptureMessage,
        withScope: mockWithScope,
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

    it('withScope is called', () => {
      Sentry.withScope(mockFn);

      expect(mockWithScope).toHaveBeenCalledWith(mockFn);
    });
  });
});
