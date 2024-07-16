const METHODS_TO_WATCH = ['error', 'warn'];

const matchesStringOrRegex = (target, strOrRegex) => {
  if (typeof strOrRegex === 'string') {
    return target === strOrRegex;
  }

  // why: We can't just check `instanceof RegExp` for some reason. I think it happens when values cross the Jest test sandbox into the outer environment.
  // Please see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145065#note_1788386920
  if ('test' in strOrRegex) {
    return strOrRegex.test(target);
  }

  throw new Error(`Unexpected value to match (${strOrRegex}). Expected string or RegExp.`);
};

export const throwErrorFromCalls = (consoleCalls) => {
  const consoleCallsList = consoleCalls
    .map(({ method, args }, idx) => `\n[${idx + 1}] ${method}: ${args}\n`)
    .join('')
    .split('\n')
    .map((x) => `\t${x}`)
    .join('\n');

  throw new Error(
    `Unexpected calls to console (${consoleCalls.length}) with:\n${consoleCallsList}\n`,
  );
};

class ConsoleWatcher {
  /**
   * Reference to the console instance that we are watching and overriding.
   *
   * @type {Console}
   */
  #console;

  /**
   * Array of RegExp's or string's that will be used to ignore certain calls.
   * These are applied to only the message received by the `ConsoleWatcher`, regardless
   * of whether it was a `console.warn` or `console.error`.
   *
   * @type {(RegExp | string)[]}
   */
  #ignores;

  /**
   * List of console method calls that were collected. This can include ignored consoles.
   * We don't filter out ignores until we `getCalls`.
   *
   * @type {{method: string, args: unknown[]}[]}
   */
  #calls;

  /**
   * @type {{ error: Function, warn: Function }} Reference to the original Console methods
   */
  #original;

  /**
   * Flag for whether to use the legacy behavior of throwing immediately
   *
   * @type {boolean}
   */
  #shouldThrowImmediately;

  constructor(console, { ignores = [], shouldThrowImmediately = false } = {}) {
    this.#console = console;
    this.#ignores = ignores;
    this.#calls = [];
    this.#original = {};
    this.#shouldThrowImmediately = shouldThrowImmediately;

    METHODS_TO_WATCH.forEach((method) => {
      const originalFn = console[method];

      this.#original[method] = originalFn;

      Object.assign(console, {
        [method]: (...args) => {
          this.#handleCall(method, args);
        },
      });
    });
  }

  dispose() {
    Object.entries(this.#original).forEach(([key, fn]) => {
      Object.assign(this.#console, { [key]: fn });
    });
  }

  getIgnores() {
    return this.#ignores;
  }

  setIgnores(ignores) {
    this.#ignores = ignores;
  }

  setShouldThrowImmediately(value) {
    this.#shouldThrowImmediately = value;
  }

  shouldThrowImmediately() {
    return this.#shouldThrowImmediately;
  }

  forgetCalls() {
    this.#calls = [];
  }

  getCalls() {
    return this.#calls.filter((call) => !this.#shouldIgnore(call));
  }

  #shouldIgnore({ args }) {
    const argsAsStr = args.map(String).join();

    return this.#ignores.some((ignoreMatcher) => matchesStringOrRegex(argsAsStr, ignoreMatcher));
  }

  #handleCall(method, args) {
    const call = { method, args };

    if (this.#shouldThrowImmediately && !this.#shouldIgnore(call)) {
      throwErrorFromCalls([call]);
      return;
    }

    this.#calls.push(call);

    this.#original[method](...args);
  }
}

/**
 * @param {CustomEnvironment} environment - Jest environment to attach the globals to
 * @param {Console} console - the instnace of Console to setup watchers.
 * @param {Object} options - optional options to use when setting up the console watcher.
 * @param {(RegExp | string)[]} options.ignores - list of console messages to ignore.
 * @param {boolean} options.shouldThrowImmediately - flag for whether we do the legacy behavior of throwing immediately.
 * @returns
 */
export const setupConsoleWatcher = (environment, console, options) => {
  if (environment.global.jestConsoleWatcher) {
    throw new Error('jestConsoleWatcher already exists');
  }

  const consoleWatcher = new ConsoleWatcher(console, options);

  // eslint-disable-next-line no-param-reassign
  environment.global.jestConsoleWatcher = consoleWatcher;

  return consoleWatcher;
};

export const forgetConsoleCalls = () => global.jestConsoleWatcher?.forgetCalls();

export const getConsoleCalls = () => global.jestConsoleWatcher?.getCalls() || [];

/**
 * Flags whether or the current `describe` should adopt the legacy test behavior of throwing immediately on `console.warn` or `console.error`
 *
 * Example:
 *
 * ```javascript
 * describe('Foo', () => {
 *   useConsoleWatcherThrowsImmediately();
 *
 *   describe('bar', () => {
 *     useConsoleWatcherThrowsImmediately(false);
 *
 *     // These tests **will not** throw immediately if `console.warn` or `console.error` is called.
 *   });
 *
 *   describe('zed', () => {
 *     // These tests **will** throw immediately if `console.warn` or `console.error` is called.
 *   })
 * });
 * ```
 *
 * @param {boolean} val - True if the consoleWatcher should throw immediately on a console method call
 * @deprecated This only exists to support legacy tests that depend on this erroneous test behavior
 */
export const useConsoleWatcherThrowsImmediately = (val = true) => {
  let origLegacy;

  beforeAll(() => {
    origLegacy = global.jestConsoleWatcher.shouldThrowImmediately();

    global.jestConsoleWatcher.setShouldThrowImmediately(val);
  });

  afterAll(() => {
    global.jestConsoleWatcher.setShouldThrowImmediately(origLegacy);
  });
};

/**
 * Sets up the console watcher to ignore the given messages for the current `describe` block.
 *
 * Example:
 *
 * ```javascript
 * describe('Foo', () => {
 *   ignoreConsoleMessages([
 *     'Hello world',
 *     /The field .* is not okay/,
 *   ]);
 *
 *   it('works', () => {
 *     // Passes :)
 *     console.error('Hello world');
 *     console.warn('The field FOO is not okay');
 *
 *     // Fail :(
 *     console.error('Hello world, strings are compared strictly.');
 *   });
 * });
 * ```
 *
 * @param {(string | RegExp)[]} ignores - Array of console messages to ignore for the current `describe` block.
 */
export const ignoreConsoleMessages = (ignores) => {
  if (!Array.isArray(ignores)) {
    throw new Error('Expected ignoreConsoleMessages to receive an Array of strings or RegExp');
  }

  let origIgnores;

  beforeAll(() => {
    origIgnores = global.jestConsoleWatcher.getIgnores();

    global.jestConsoleWatcher.setIgnores(origIgnores.concat(ignores));
  });

  afterAll(() => {
    global.jestConsoleWatcher.setIgnores(origIgnores);
  });
};

export const ignoreVueConsoleWarnings = () =>
  ignoreConsoleMessages([/^\[Vue warn\]: Missing required prop/, /^\[Vue warn\]: Invalid prop/]);
