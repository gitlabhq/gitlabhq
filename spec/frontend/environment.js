/* eslint-disable import/no-commonjs, max-classes-per-file */

const path = require('path');
const JSDOMEnvironment = require('jest-environment-jsdom');
const { ErrorWithStack } = require('jest-util');
const {
  setGlobalDateToFakeDate,
  setGlobalDateToRealDate,
} = require('./__helpers__/fake_date/fake_date');
const { TEST_HOST } = require('./__helpers__/test_constants');

const ROOT_PATH = path.resolve(__dirname, '../..');

class CustomEnvironment extends JSDOMEnvironment {
  constructor(config, context) {
    // Setup testURL so that window.location is setup properly
    super({ ...config, testURL: TEST_HOST }, context);

    // Fake the `Date` for `jsdom` which fixes things like document.cookie
    // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/39496#note_503084332
    setGlobalDateToFakeDate();

    Object.assign(context.console, {
      error(...args) {
        throw new ErrorWithStack(
          `Unexpected call of console.error() with:\n\n${args.join(', ')}`,
          this.error,
        );
      },

      warn(...args) {
        throw new ErrorWithStack(
          `Unexpected call of console.warn() with:\n\n${args.join(', ')}`,
          this.warn,
        );
      },
    });

    const { testEnvironmentOptions } = config;
    const { IS_EE } = testEnvironmentOptions;
    this.global.gon = {
      ee: IS_EE,
    };
    this.global.IS_EE = IS_EE;

    this.rejectedPromises = [];

    this.global.promiseRejectionHandler = (error) => {
      this.rejectedPromises.push(error);
    };

    this.global.fixturesBasePath = `${ROOT_PATH}/tmp/tests/frontend/fixtures${IS_EE ? '-ee' : ''}`;
    this.global.staticFixturesBasePath = `${ROOT_PATH}/spec/frontend/fixtures`;

    /**
     * window.fetch() is required by the apollo-upload-client library otherwise
     * a ReferenceError is generated: https://github.com/jaydenseric/apollo-upload-client/issues/100
     */
    this.global.fetch = () => {};

    // Expose the jsdom (created in super class) to the global so that we can call reconfigure({ url: '' }) to properly set `window.location`
    this.global.jsdom = this.dom;

    Object.assign(this.global.performance, {
      mark: () => null,
      measure: () => null,
      getEntriesByName: () => [],
    });

    //
    // Monaco-related environment variables
    //
    this.global.MonacoEnvironment = { globalAPI: true };
    Object.defineProperty(this.global, 'matchMedia', {
      writable: true,
      value: (query) => ({
        matches: false,
        media: query,
        onchange: null,
        addListener: () => null, // deprecated
        removeListener: () => null, // deprecated
        addEventListener: () => null,
        removeEventListener: () => null,
        dispatchEvent: () => null,
      }),
    });

    this.global.PerformanceObserver = class {
      /* eslint-disable no-useless-constructor, no-unused-vars, no-empty-function, class-methods-use-this */
      constructor(callback) {}
      disconnect() {}
      observe(element, initObject) {}
      /* eslint-enable no-useless-constructor, no-unused-vars, no-empty-function, class-methods-use-this */
    };
  }

  async teardown() {
    // Reset `Date` so that Jest can report timing accurately *roll eyes*...
    setGlobalDateToRealDate();

    await new Promise(setImmediate);

    if (this.rejectedPromises.length > 0) {
      throw new ErrorWithStack(
        `Unhandled Promise rejections: ${this.rejectedPromises.join(', ')}`,
        this.teardown,
      );
    }

    await super.teardown();
  }
}

module.exports = CustomEnvironment;
