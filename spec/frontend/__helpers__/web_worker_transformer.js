/* eslint-disable import-x/no-commonjs */
const { createTransformer } = require('babel-jest');

// This Jest will transform the code of a WebWorker module into a FakeWebWorker subclass.
// This is meant to mirror Webpack's [`worker-loader`][1].
// [1]: https://webpack.js.org/loaders/worker-loader/
module.exports = {
  process: (contentArg, filename, ...args) => {
    const { code: content } = createTransformer().process(contentArg, filename, ...args);

    const fakeWorkerPath = JSON.stringify(require.resolve('./web_worker_fake'));
    const workerPath = JSON.stringify(filename);
    const workerCode = JSON.stringify(content);

    const jestTransformedWorkerCode = `const { FakeWebWorker } = require(${fakeWorkerPath});
    module.exports = class JestTransformedWorker extends FakeWebWorker {
      constructor() {
        super(${workerPath}, ${workerCode});
      }
    };`;

    return {
      code: jestTransformedWorkerCode,
    };
  },
};
