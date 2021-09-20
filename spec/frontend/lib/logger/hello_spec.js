import { logHello } from '~/lib/logger/hello';

describe('~/lib/logger/hello', () => {
  let consoleLogSpy;

  beforeEach(() => {
    // We don't `mockImplementation` so we can validate there's no errors thrown
    consoleLogSpy = jest.spyOn(console, 'log');
  });

  describe('logHello', () => {
    it('console logs a friendly hello message', () => {
      expect(consoleLogSpy).not.toHaveBeenCalled();

      logHello();

      expect(consoleLogSpy.mock.calls).toMatchSnapshot();
    });
  });
});
