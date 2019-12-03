/* eslint-disable import/no-commonjs */

const path = require('path');
const { ErrorWithStack } = require('jest-util');
const JSDOMEnvironment = require('jest-environment-jsdom');

const ROOT_PATH = path.resolve(__dirname, '../..');

class CustomEnvironment extends JSDOMEnvironment {
  constructor(config, context) {
    super(config, context);

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

    this.global.promiseRejectionHandler = error => {
      this.rejectedPromises.push(error);
    };

    this.global.fixturesBasePath = `${ROOT_PATH}/tmp/tests/frontend/fixtures${IS_EE ? '-ee' : ''}`;
    this.global.staticFixturesBasePath = `${ROOT_PATH}/spec/frontend/fixtures`;

    /**
     * window.fetch() is required by the apollo-upload-client library otherwise
     * a ReferenceError is generated: https://github.com/jaydenseric/apollo-upload-client/issues/100
     */
    this.global.fetch = () => {};

    // Not yet supported by JSDOM: https://github.com/jsdom/jsdom/issues/317
    this.global.document.createRange = () => ({
      setStart: () => {},
      setEnd: () => {},
      commonAncestorContainer: {
        nodeName: 'BODY',
        ownerDocument: this.global.document,
      },
    });
  }

  async teardown() {
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
