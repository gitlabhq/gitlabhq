/* eslint-disable import/no-commonjs */

const { ErrorWithStack } = require('jest-util');
const JSDOMEnvironment = require('jest-environment-jsdom');

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
    this.global.gon = {
      ee: testEnvironmentOptions.IS_EE,
    };

    this.rejectedPromises = [];

    this.global.promiseRejectionHandler = error => {
      this.rejectedPromises.push(error);
    };
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
