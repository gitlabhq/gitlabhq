/**
 * Instead of messing around with timers, we execute deferred functions
 * immediately in our specs
 */
export default (fn, ...args) => fn(...args);
