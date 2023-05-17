/**
 * A promise that is also tappable, i.e. something you can subscribe
 * to to get progress of a promise until it resolves.
 *
 * @example Usage
 *   const tp = new TappablePromise((resolve, reject, tap) => {
 *     for (let i = 0; i < 10; i++) {
 *       tap(i/10);
 *     }
 *     resolve();
 *   });
 *
 *  tp.tap((progress) => {
 *    console.log(progress);
 *  }).then(() => {
 *    console.log('done');
 *  });
 *
 *  // Output:
 *  // 0
 *  // 0.1
 *  // 0.2
 *  // ...
 *  // 0.9
 *  // done
 *
 *
 * @param {(resolve: Function, reject: Function, tap: Function) => void} callback
 * @returns {Promise & { tap: Function }}}
 */
export default function TappablePromise(callback) {
  let progressCallback;

  const promise = new Promise((resolve, reject) => {
    try {
      const tap = (progress) => progressCallback?.(progress);
      resolve(callback(tap, resolve, reject));
    } catch (e) {
      reject(e);
    }
  });

  promise.tap = function tap(_progressCallback) {
    progressCallback = _progressCallback;
    return this;
  };

  return promise;
}
