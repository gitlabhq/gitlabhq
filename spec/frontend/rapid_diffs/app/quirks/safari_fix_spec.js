import { fixWebComponentsStreamingOnSafari } from '~/rapid_diffs/app/quirks/safari_fix';

describe('fixWebComponentsStreamingOnSafari', () => {
  const originalUserAgent = navigator.userAgent;
  const safariUserAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/27.0 Safari/605.1.15';
  const chromeUserAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36';
  const wrongDocumentMessage = 'A newly constructed custom element belongs to a wrong document';

  let cleanup;
  let globalErrorHandler;

  const setUserAgent = (value) => {
    Object.defineProperty(navigator, 'userAgent', { value, configurable: true });
  };

  const dispatchError = (error) => {
    const event = new ErrorEvent('error', { error, message: error.message, cancelable: true });
    window.dispatchEvent(event);
    return event;
  };

  const wrongDocumentError = () => new DOMException(wrongDocumentMessage, 'NotSupportedError');

  beforeEach(() => {
    globalErrorHandler = jest.fn();
    window.addEventListener('error', globalErrorHandler);
  });

  afterEach(() => {
    cleanup?.();
    cleanup = undefined;
    window.removeEventListener('error', globalErrorHandler);
    setUserAgent(originalUserAgent);
  });

  describe('on Safari', () => {
    beforeEach(() => {
      setUserAgent(safariUserAgent);
      cleanup = fixWebComponentsStreamingOnSafari(document.createElement('div'));
    });

    it('suppresses wrong document errors', () => {
      const event = dispatchError(wrongDocumentError());

      expect(event.defaultPrevented).toBe(true);
      expect(globalErrorHandler).not.toHaveBeenCalled();
    });

    it.each([
      ['a different message', new DOMException('Something else', 'NotSupportedError')],
      ['a different error type', new Error(wrongDocumentMessage)],
    ])('does not suppress errors with %s', (_, error) => {
      const event = dispatchError(error);

      expect(event.defaultPrevented).toBe(false);
      expect(globalErrorHandler).toHaveBeenCalledTimes(1);
    });

    it('stops suppressing errors after cleanup', () => {
      cleanup();
      cleanup = undefined;

      const event = dispatchError(wrongDocumentError());

      expect(event.defaultPrevented).toBe(false);
      expect(globalErrorHandler).toHaveBeenCalledTimes(1);
    });

    it('keeps suppressing errors for a newer stream after an older stream cleans up', () => {
      const newerCleanup = fixWebComponentsStreamingOnSafari(document.createElement('div'));
      cleanup();
      cleanup = newerCleanup;

      const event = dispatchError(wrongDocumentError());

      expect(event.defaultPrevented).toBe(true);
      expect(globalErrorHandler).not.toHaveBeenCalled();
    });
  });

  describe('on Chrome', () => {
    it('does not suppress wrong document errors', () => {
      setUserAgent(chromeUserAgent);
      cleanup = fixWebComponentsStreamingOnSafari(document.createElement('div'));

      const event = dispatchError(wrongDocumentError());

      expect(event.defaultPrevented).toBe(false);
      expect(globalErrorHandler).toHaveBeenCalledTimes(1);
    });
  });
});
