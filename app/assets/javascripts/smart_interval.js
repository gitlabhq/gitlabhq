import $ from 'jquery';

/**
 * Instances of SmartInterval extend the functionality of `setInterval`, make it configurable
 * and controllable by a public API.
 *
 * This component has two intervals:
 *
 * - current interval - when the page is visible - defined by `startingInterval`, `maxInterval`, and `incrementByFactorOf`
 *   - Example:
 *     - `startingInterval: 10000`, `maxInterval: 240000`, `incrementByFactorOf: 2`
 *     - results in `10s, 20s, 40s, 80s, ..., 240s`, it stops increasing at `240s` and keeps this interval indefinitely.
 * - hidden interval - when the page is not visible
 *
 * Visibility transitions:
 *
 * - `visible -> not visible`
 *   - `document.addEventListener('visibilitychange', () => ...)`
 *
 *       > This event fires with a visibilityState of hidden when a user navigates to a new page, switches tabs, closes the tab, minimizes or closes the browser, or, on mobile, switches from the browser to a different app.
 *
 *       Source [Document: visibilitychange event - Web APIs | MDN](https://developer.mozilla.org/en-US/docs/Web/API/Document/visibilitychange_event)
 *
 *   - `window.addEventListener('blur', () => ...)` - every time user clicks somewhere else then in the browser page
 * - `not visible -> visible`
 *   - `document.addEventListener('visibilitychange', () => ...)` same as the transition `visible -> not visible`
 *   - `window.addEventListener('focus', () => ...)`
 *
 * The combination of these two listeners can result in an unexpected resumption of polling:
 *
 * - switch to a different window (causes `blur`)
 * - switch to a different desktop (causes `visibilitychange` (not visible))
 * - switch back to the original desktop (causes `visibilitychange` (visible))
 * - *now the polling happens even in window that user doesn't work in*
 */

export default class SmartInterval {
  /**
   * @param { function } opts.callback Function that returns a promise, called on each iteration
   *                     unless still in progress (required)
   * @param { milliseconds } opts.startingInterval `currentInterval` is set to this initially
   * @param { milliseconds } opts.maxInterval `currentInterval` will be incremented to this
   * @param { milliseconds } opts.hiddenInterval `currentInterval` is set to this
   *                         when the page is hidden
   * @param { integer } opts.incrementByFactorOf `currentInterval` is incremented by this factor
   * @param { boolean } opts.lazyStart Configure if timer is initialized on
   *                    instantiation or lazily
   * @param { boolean } opts.immediateExecution Configure if callback should
   *                    be executed before the first interval.
   */
  constructor(opts = {}) {
    this.cfg = {
      callback: opts.callback,
      startingInterval: opts.startingInterval,
      maxInterval: opts.maxInterval,
      hiddenInterval: opts.hiddenInterval,
      incrementByFactorOf: opts.incrementByFactorOf,
      lazyStart: opts.lazyStart,
      immediateExecution: opts.immediateExecution,
    };

    this.state = {
      intervalId: null,
      currentInterval: this.cfg.startingInterval,
      pagevisibile: true,
    };

    this.initInterval();
  }

  /* public */

  start() {
    const { cfg, state } = this;

    if (cfg.immediateExecution && !this.isLoading) {
      cfg.immediateExecution = false;
      this.triggerCallback();
    }

    state.intervalId = window.setInterval(() => {
      if (this.isLoading) {
        return;
      }
      this.triggerCallback();

      if (this.getCurrentInterval() === cfg.maxInterval) {
        return;
      }

      this.incrementInterval();
      this.resume();
    }, this.getCurrentInterval());
  }

  // cancel the existing timer, setting the currentInterval back to startingInterval
  cancel() {
    this.setCurrentInterval(this.cfg.startingInterval);
    this.stopTimer();
  }

  onVisibilityHidden() {
    if (this.cfg.hiddenInterval) {
      this.setCurrentInterval(this.cfg.hiddenInterval);
      this.resume();
    } else {
      this.cancel();
    }
  }

  // start a timer, using the existing interval
  resume() {
    this.stopTimer(); // stop existing timer, in case timer was not previously stopped
    this.start();
  }

  onVisibilityVisible() {
    this.cancel();
    this.start();
  }

  destroy() {
    document.removeEventListener('visibilitychange', this.onVisibilityChange);
    window.removeEventListener('blur', this.onWindowVisibilityChange);
    window.removeEventListener('focus', this.onWindowVisibilityChange);
    this.cancel();
    // eslint-disable-next-line @gitlab/no-global-event-off
    $(document).off('visibilitychange').off('beforeunload');
  }

  /* private */

  initInterval() {
    const { cfg } = this;

    if (!cfg.lazyStart) {
      this.start();
    }

    this.initVisibilityChangeHandling();
    this.initPageUnloadHandling();
  }

  triggerCallback() {
    this.isLoading = true;
    this.cfg
      .callback()
      .then(() => {
        this.isLoading = false;
      })
      .catch((err) => {
        this.isLoading = false;
        throw err;
      });
  }

  onWindowVisibilityChange(e) {
    this.state.pagevisibile = e.type === 'focus';
    this.handleVisibilityChange();
  }

  onVisibilityChange(e) {
    this.state.pagevisibile = e.target.visibilityState === 'visible';
    this.handleVisibilityChange();
  }

  initVisibilityChangeHandling() {
    // cancel interval when tab or window is no longer shown (prevents cached pages from polling)
    document.addEventListener('visibilitychange', this.onVisibilityChange.bind(this));
    window.addEventListener('blur', this.onWindowVisibilityChange.bind(this));
    window.addEventListener('focus', this.onWindowVisibilityChange.bind(this));
  }

  initPageUnloadHandling() {
    // TODO: Consider refactoring in light of turbolinks removal.
    // prevent interval continuing after page change, when kept in cache by Turbolinks
    $(document).on('beforeunload', () => this.cancel());
  }

  handleVisibilityChange() {
    const intervalAction = this.isPageVisible()
      ? this.onVisibilityVisible
      : this.onVisibilityHidden;

    intervalAction.apply(this);
  }

  getCurrentInterval() {
    return this.state.currentInterval;
  }

  setCurrentInterval(newInterval) {
    this.state.currentInterval = newInterval;
  }

  incrementInterval() {
    const { cfg } = this;
    const currentInterval = this.getCurrentInterval();
    if (cfg.hiddenInterval && !this.isPageVisible()) return;
    let nextInterval = currentInterval * cfg.incrementByFactorOf;

    if (nextInterval > cfg.maxInterval) {
      nextInterval = cfg.maxInterval;
    }

    this.setCurrentInterval(nextInterval);
  }

  isPageVisible() {
    return this.state.pagevisibile;
  }

  stopTimer() {
    const { state } = this;

    state.intervalId = window.clearInterval(state.intervalId);
  }
}
