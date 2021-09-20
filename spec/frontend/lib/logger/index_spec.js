import { logError, LOG_PREFIX } from '~/lib/logger';

describe('~/lib/logger', () => {
  let consoleErrorSpy;

  beforeEach(() => {
    consoleErrorSpy = jest.spyOn(console, 'error');
    consoleErrorSpy.mockImplementation();
  });

  describe('logError', () => {
    it('sends given message to console.error', () => {
      const message = 'Lorem ipsum dolar sit amit';
      const error = new Error('lorem ipsum');

      expect(consoleErrorSpy).not.toHaveBeenCalled();

      logError(message, error);

      expect(consoleErrorSpy).toHaveBeenCalledWith(LOG_PREFIX, `${message}\n`, error);
    });
  });
});
