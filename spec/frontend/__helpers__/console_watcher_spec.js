import {
  setupConsoleWatcher,
  throwErrorFromCalls,
  forgetConsoleCalls,
  getConsoleCalls,
  ignoreConsoleMessages,
  // eslint-disable-next-line import/no-deprecated
  useConsoleWatcherThrowsImmediately,
} from './console_watcher';

const TEST_IGNORED_MESSAGE = 'Full message to ignore.';
const TEST_IGNORED_REGEX_MESSAGE = 'Part of this message matches partial ignore.';

describe('__helpers__/console_watcher', () => {
  let testEnvironment;
  let testConsole;
  let testConsoleOriginalFn;
  let consoleWatcher;

  const callConsoleMethods = () => {
    testConsole.log('Hello world log');
    testConsole.info('Hello world info');
    testConsole.info(TEST_IGNORED_MESSAGE);
    testConsole.warn(TEST_IGNORED_REGEX_MESSAGE);
    testConsole.warn('Hello world warn');
    testConsole.error('Hello world error');
    testConsole.error(TEST_IGNORED_MESSAGE);
  };

  // note: To test the beforeAll/afterAll behavior in some parts of console_watcher, we need to have our setup
  //       use beforeAll/afterAll instead of beforeEach/afterEach.
  beforeAll(() => {
    testEnvironment = { global: {} };
    testConsole = {
      log: (...args) => testConsoleOriginalFn('log', ...args),
      info: (...args) => testConsoleOriginalFn('info', ...args),
      warn: (...args) => testConsoleOriginalFn('warn', ...args),
      error: (...args) => testConsoleOriginalFn('error', ...args),
    };
    Object.defineProperty(global, 'jestConsoleWatcher', {
      get() {
        return testEnvironment.global.jestConsoleWatcher;
      },
    });
  });

  beforeEach(() => {
    // why: Let's make sure we have a fresh spy for every test
    testConsoleOriginalFn = jest.fn();
  });

  afterEach(() => {
    // why: We need to forget calls or else our main test_setup will pick up on console calls and throw an error
    forgetConsoleCalls();
  });

  describe('throwErrorFromCalls', () => {
    it('throws error with message containing calls', () => {
      const calls = [
        { method: 'error', args: ['Hello world', 2, 'Lorem\nIpsum\nDolar\nSit'] },
        { method: 'info', args: [] },
        { method: 'warn', args: ['Hello world', 'something bad happened'] },
      ];

      expect(() => throwErrorFromCalls(calls)).toThrowErrorMatchingInlineSnapshot(`
"Unexpected calls to console (3) with:
	
	[1] error: Hello world,2,Lorem
	Ipsum
	Dolar
	Sit
	
	[2] info: 
	
	[3] warn: Hello world,something bad happened
	
"
`);
    });
  });

  describe('setupConsoleWatcher', () => {
    beforeAll(() => {
      testEnvironment = { global: {} };
      consoleWatcher = setupConsoleWatcher(testEnvironment, testConsole, {
        ignores: ['Full message to ignore.', /partial ignore/],
      });
    });

    afterAll(() => {
      consoleWatcher.dispose();
    });

    describe.each(['warn', 'error'])('with %s', (method) => {
      it('with unexpected message, calls original console method', () => {
        testConsole[method]('BOOM!');

        expect(testConsoleOriginalFn).toHaveBeenCalledTimes(1);
        expect(testConsoleOriginalFn).toHaveBeenCalledWith(method, 'BOOM!');
      });

      it('with ignored message, calls original console method', () => {
        testConsole[method](TEST_IGNORED_MESSAGE);

        expect(testConsoleOriginalFn).toHaveBeenCalledTimes(1);
        expect(testConsoleOriginalFn).toHaveBeenCalledWith(method, TEST_IGNORED_MESSAGE);
      });
    });

    describe('with ignoreConsoleMessages', () => {
      ignoreConsoleMessages([/Hello world .*/]);

      it('adds to ignored messages only for describe block', () => {
        callConsoleMethods();

        expect(getConsoleCalls()).toEqual([]);
      });
    });

    describe('with useConsoleWatcherThrowsImmediately', () => {
      // eslint-disable-next-line import/no-deprecated
      useConsoleWatcherThrowsImmediately();

      it('throws when non ignored message', () => {
        expect(callConsoleMethods).toThrow();
      });
    });

    it('with getConsoleCalls, only returns non ignored ones', () => {
      expect(getConsoleCalls()).toEqual([]);

      callConsoleMethods();

      expect(getConsoleCalls()).toEqual([
        { method: 'warn', args: ['Hello world warn'] },
        { method: 'error', args: ['Hello world error'] },
      ]);
    });

    it('with forgetConsoleCalls, clears out calls', () => {
      callConsoleMethods();
      forgetConsoleCalls();

      expect(getConsoleCalls()).toEqual([]);
    });
  });

  describe('setupConsoleWatcher with shouldThrowImmediately', () => {
    beforeAll(() => {
      testEnvironment = { global: {} };
      consoleWatcher = setupConsoleWatcher(testEnvironment, testConsole, {
        ignores: ['Full message to ignore.', /partial ignore/],
        shouldThrowImmediately: true,
      });
    });

    afterAll(() => {
      consoleWatcher.dispose();
    });

    it('does not throw on ignored call', () => {
      expect(() => testConsole.error(TEST_IGNORED_MESSAGE)).not.toThrow();
    });

    it('throws when call is not ignored', () => {
      expect(() => testConsole.error('BLOW UP!')).toThrowErrorMatchingInlineSnapshot(`
"Unexpected calls to console (1) with:
	
	[1] error: BLOW UP!
	
"
`);
    });
  });
});
