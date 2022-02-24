/**
 * This will wrap the given function to make sure that it is only triggered once
 * while executing asynchronously
 *
 * @param {Function} fn some function that returns a promise
 * @returns A function that will only be triggered *once* while the promise is executing
 */
export const ignoreWhilePending = (fn) => {
  const isPendingMap = new WeakMap();
  const defaultContext = {};

  // We need this to be a function so we get the `this`
  return function ignoreWhilePendingInner(...args) {
    const context = this || defaultContext;

    if (isPendingMap.get(context)) {
      return Promise.resolve();
    }

    isPendingMap.set(context, true);

    return fn.apply(this, args).finally(() => {
      isPendingMap.delete(context);
    });
  };
};
