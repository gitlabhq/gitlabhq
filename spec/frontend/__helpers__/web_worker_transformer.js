/* eslint-disable import/no-commonjs */
const { createTransformer } = require('babel-jest');

// This Jest will transform the code of a WebWorker module into a FakeWebWorker subclass.
// This is meant to mirror Webpack's [`worker-loader`][1].
// [1]: https://webpack.js.org/loaders/worker-loader/
module.exports = {
  process: (contentArg, filename, ...args) => {
    const { code: content } = createTransformer().process(contentArg, filename, ...args);

    const jestTransformedWorkerCode = `const { FakeWebWorker } = require("helpers/web_worker_fake");
    module.exports = class JestTransformedWorker extends FakeWebWorker {
      constructor() {
        super(${JSON.stringify(filename)}, ${JSON.stringify(content)});
      }
    };`;

    return {
      code: jestTransformedWorkerCode,
    };
  },
};
