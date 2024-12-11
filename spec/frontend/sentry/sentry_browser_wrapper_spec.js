/* eslint-disable no-console */

import * as Sentry from '~/sentry/sentry_browser_wrapper';

const mockError = new Error('error!');
const mockBreadcrumb = { category: 'mockCategory' };

describe('SentryBrowserWrapper', () => {
  beforeAll(() => {
    process.env.NODE_ENV = 'development';
  });

  afterAll(() => {
    process.env.NODE_ENV = 'test';
  });

  beforeEach(() => {
    jest.spyOn(console, 'error').mockImplementation();
    jest.spyOn(console, 'debug').mockImplementation();
  });

  afterEach(() => {
    console.error.mockRestore();
    console.debug.mockRestore();

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

    it('addBreadcrumb will report to console instead', () => {
      Sentry.addBreadcrumb(mockBreadcrumb);

      expect(console.debug).toHaveBeenCalledTimes(1);
      expect(console.debug).toHaveBeenCalledWith(
        '[Sentry stub]',
        'addBreadcrumb(...) called with:',
        { 0: mockBreadcrumb },
      );
    });
  });

  describe('when _Sentry is defined', () => {
    let mockCaptureException;
    let mockAddBreadcrumb;

    beforeEach(() => {
      mockCaptureException = jest.fn();
      mockAddBreadcrumb = jest.fn();

      // eslint-disable-next-line no-underscore-dangle
      window._Sentry = {
        captureException: mockCaptureException,
        addBreadcrumb: mockAddBreadcrumb,
      };
    });

    it('captureException is called', () => {
      Sentry.captureException(mockError);

      expect(mockCaptureException).toHaveBeenCalledWith(mockError);
    });

    it('addBreadcrumb is called', () => {
      Sentry.addBreadcrumb(mockBreadcrumb);

      expect(mockAddBreadcrumb).toHaveBeenCalledWith(mockBreadcrumb);
    });
  });
});
