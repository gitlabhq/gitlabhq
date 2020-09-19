/**
 * This function replaces the existing `setTimeout` and `setInterval` with wrappers that
 * discount the `ms` passed in by `boost`.
 *
 * For example, if a module has:
 *
 * ```
 * setTimeout(cb, 100);
 * ```
 *
 * But a test has:
 *
 * ```
 * useOverclockTimers(25);
 * ```
 *
 * Then the module's call to `setTimeout` effectively becomes:
 *
 * ```
 * setTimeout(cb, 4);
 * ```
 *
 * It's important to note that the timing for `setTimeout` and order of execution is non-deterministic
 * and discounting the `ms` passed could make this very obvious and expose some underlying issues
 * with flaky failures.
 *
 * WARNING: If flaky spec failures show up in a spec that is using this helper, please consider either:
 *
 *   - Refactoring the production code so that it's reactive to state changes, not dependent on timers.
 *   - Removing the call to this helper from the spec.
 *
 * @param {Number} boost
 */
export const useOverclockTimers = (boost = 50) => {
  if (boost <= 0) {
    throw new Error(`[overclock_timers] boost (${boost}) cannot be <= 0`);
  }

  let origSetTimeout;
  let origSetInterval;
  const newSetTimeout = (fn, msParam = 0) => {
    const ms = msParam > 0 ? Math.floor(msParam / boost) : msParam;

    return origSetTimeout(fn, ms);
  };
  const newSetInterval = (fn, msParam = 0) => {
    const ms = msParam > 0 ? Math.floor(msParam / boost) : msParam;

    return origSetInterval(fn, ms);
  };

  beforeEach(() => {
    origSetTimeout = global.setTimeout;
    origSetInterval = global.setInterval;

    global.setTimeout = newSetTimeout;
    global.setInterval = newSetInterval;
  });

  afterEach(() => {
    global.setTimeout = origSetTimeout;
    global.setInterval = origSetInterval;
  });
};
