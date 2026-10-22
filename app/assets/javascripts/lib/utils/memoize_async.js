import { memoize } from 'lodash-es';

/**
 * Wraps an async function in Lodash's `memoize`, but doesn't cache rejections;
 * any subsequent awaits on a key that rejected last time will re-attempt the call.
 *
 * @param {(key: *) => Promise<*>} fn A unary async function; the argument is used as the cache key.
 * @returns {((key: *) => Promise<*>) & { cache: Map<*, Promise<*>> }} The memoized async function.
 */
export const memoizeAsync = (fn) => {
  const memoized = memoize((key) => {
    const promise = fn(key);
    promise.catch(() => memoized.cache.delete(key));
    return promise;
  });

  return memoized;
};
