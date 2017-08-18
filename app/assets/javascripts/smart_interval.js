/**
 * Instances of SmartInterval extend the functionality of `setInterval`, make it configurable
 * and controllable by a public API.
 */

class SmartInterval {
  /**
   * @param { function } opts.callback Function to be called on each iteration (required)
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
      pageVisibility: 'visible',
    };

    this.initInterval();
  }

  /* public */

  start() {
    const cfg = this.cfg;
    const state = this.state;

    if (cfg.immediateExecution) {
      cfg.immediateExecution = false;
      cfg.callback();
    }

    state.intervalId = window.setInterval(() => {
      cfg.callback();

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
    this.stopTimer(); // stop exsiting timer, in case timer was not previously stopped
    this.start();
  }

  onVisibilityVisible() {
    this.cancel();
    this.start();
  }

  destroy() {
    this.cancel();
    document.removeEventListener('visibilitychange', this.handleVisibilityChange);
    $(document).off('visibilitychange').off('beforeunload');
  }

  /* private */

  initInterval() {
    const cfg = this.cfg;

    if (!cfg.lazyStart) {
      this.start();
    }

    this.initVisibilityChangeHandling();
    this.initPageUnloadHandling();
  }

  initVisibilityChangeHandling() {
    // cancel interval when tab no longer shown (prevents cached pages from polling)
    document.addEventListener('visibilitychange', this.handleVisibilityChange.bind(this));
  }

  initPageUnloadHandling() {
    // TODO: Consider refactoring in light of turbolinks removal.
    // prevent interval continuing after page change, when kept in cache by Turbolinks
    $(document).on('beforeunload', () => this.cancel());
  }

  handleVisibilityChange(e) {
    this.state.pageVisibility = e.target.visibilityState;
    const intervalAction = this.isPageVisible() ?
      this.onVisibilityVisible :
      this.onVisibilityHidden;

    intervalAction.apply(this);
  }

  getCurrentInterval() {
    return this.state.currentInterval;
  }

  setCurrentInterval(newInterval) {
    this.state.currentInterval = newInterval;
  }

  incrementInterval() {
    const cfg = this.cfg;
    const currentInterval = this.getCurrentInterval();
    if (cfg.hiddenInterval && !this.isPageVisible()) return;
    let nextInterval = currentInterval * cfg.incrementByFactorOf;

    if (nextInterval > cfg.maxInterval) {
      nextInterval = cfg.maxInterval;
    }

    this.setCurrentInterval(nextInterval);
  }

  isPageVisible() { return this.state.pageVisibility === 'visible'; }

  stopTimer() {
    const state = this.state;

    state.intervalId = window.clearInterval(state.intervalId);
  }
}

window.gl.SmartInterval = SmartInterval;
