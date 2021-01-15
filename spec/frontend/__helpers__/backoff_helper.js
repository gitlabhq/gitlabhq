/**
 * A mock version of a commonUtils `backOff` to test multiple
 * retries.
 *
 * Usage:
 *
 * ```
 * import * as commonUtils from '~/lib/utils/common_utils';
 * import { backoffMockImplementation } from '../../helpers/backoff_helper';
 *
 * beforeEach(() => {
 *   // ...
 *   jest.spyOn(commonUtils, 'backOff').mockImplementation(backoffMockImplementation);
 * });
 * ```
 *
 * @param {Function} callback
 */
export const backoffMockImplementation = (callback) => {
  const q = new Promise((resolve, reject) => {
    const stop = (arg) => (arg instanceof Error ? reject(arg) : resolve(arg));
    const next = () => callback(next, stop);
    // Define a timeout based on a mock timer
    setTimeout(() => {
      callback(next, stop);
    });
  });
  // Run all resolved promises in chain
  jest.runOnlyPendingTimers();
  return q;
};

export default { backoffMockImplementation };
