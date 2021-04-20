import path from 'path';

const isRelative = (pathArg) => pathArg.startsWith('.');

const transformRequirePath = (base, pathArg) => {
  if (!isRelative(pathArg)) {
    return pathArg;
  }

  return path.resolve(base, pathArg);
};

const createRelativeRequire = (filename) => {
  const rel = path.relative(__dirname, path.dirname(filename));
  const base = path.resolve(__dirname, rel);

  // reason: Dynamic require should be fine here since the code is dynamically evaluated anyways.
  // eslint-disable-next-line import/no-dynamic-require, global-require
  return (pathArg) => require(transformRequirePath(base, pathArg));
};

/**
 * Simulates a WebWorker module similar to the kind created by Webpack's [`worker-loader`][1]
 *
 * [1]: https://webpack.js.org/loaders/worker-loader/
 */
export class FakeWebWorker {
  /**
   * Constructs a new FakeWebWorker instance
   *
   * @param {String} filename is the full path of the code, which is used to resolve relative imports.
   * @param {String} code is the raw code of the web worker, which is dynamically evaluated on construction.
   */
  constructor(filename, code) {
    let isAlive = true;

    const clientTarget = new EventTarget();
    const workerTarget = new EventTarget();

    this.addEventListener = (...args) => clientTarget.addEventListener(...args);
    this.removeEventListener = (...args) => clientTarget.removeEventListener(...args);
    this.postMessage = (message) => {
      if (!isAlive) {
        return;
      }

      workerTarget.dispatchEvent(new MessageEvent('message', { data: message }));
    };
    this.terminate = () => {
      isAlive = false;
    };

    const workerScope = {
      addEventListener: (...args) => workerTarget.addEventListener(...args),
      removeEventListener: (...args) => workerTarget.removeEventListener(...args),
      postMessage: (message) => {
        if (!isAlive) {
          return;
        }

        clientTarget.dispatchEvent(new MessageEvent('message', { data: message }));
      },
    };

    // reason: `no-new-func` is like `eval` except it only executed on global scope and it's easy
    // to pass in local references. `eval` is very unsafe in production, but in our test environment
    // we shold be fine.
    // eslint-disable-next-line no-new-func
    Function('self', 'require', code)(workerScope, createRelativeRequire(filename));
  }
}
