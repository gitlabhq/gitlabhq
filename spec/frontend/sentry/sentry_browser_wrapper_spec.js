/* eslint-disable no-console */

import * as Sentry from '~/sentry/sentry_browser_wrapper';

const mockError = new Error('error!');

describe('SentryBrowserWrapper', () => {
  beforeAll(() => {
    process.env.NODE_ENV = 'development';
  });

  afterAll(() => {
    process.env.NODE_ENV = 'test';
  });

  beforeEach(() => {
    jest.spyOn(console, 'error').mockImplementation();
  });

  afterEach(() => {
    console.error.mockRestore();

    // eslint-disable-next-line no-underscore-dangle
    delete window._Sentry;
  });

  describe('when _Sentry is not defined', () => {
    it('captureException will report to console instead', () => {
      Sentry.captureException(mockError);

      expect(console.error).toHaveBeenCalledTimes(1);
      expect(console.error).toHaveBeenCalledWith(
        '[Sentry stub]',
        'captureException(...) called with:',
        { 0: mockError },
      );
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
