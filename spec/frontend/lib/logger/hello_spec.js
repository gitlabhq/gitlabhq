import { logHello } from '~/lib/logger/hello';

describe('~/lib/logger/hello', () => {
  let consoleLogSpy;

  beforeEach(() => {
    // We don't `mockImplementation` so we can validate there's no errors thrown
    consoleLogSpy = jest.spyOn(console, 'log');
  });

  describe('logHello', () => {
    describe('when on dot_com', () => {
      beforeEach(() => {
        gon.dot_com = true;
      });

      it('console logs a friendly hello message including the careers page', () => {
        expect(consoleLogSpy).not.toHaveBeenCalled();

        logHello();

        expect(consoleLogSpy.mock.calls).toMatchSnapshot();
      });
    });

    describe('when on self managed', () => {
      beforeEach(() => {
        gon.dot_com = false;
      });

      it('console logs a friendly hello message without including the careers page', () => {
        expect(consoleLogSpy).not.toHaveBeenCalled();

        logHello();

        expect(consoleLogSpy.mock.calls).toMatchSnapshot();
      });
    });
  });
});
