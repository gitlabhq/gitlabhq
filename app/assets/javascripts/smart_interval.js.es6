/*
* Instances of SmartInterval extend the functionality of `setInterval`, make it configurable
* and controllable by a public API.
*
* */

(() => {
  class SmartInterval {
    /**
      * @param { function } callback Function to be called on each iteration (required)
      * @param { milliseconds } startingInterval `currentInterval` is set to this initially
      * @param { milliseconds } maxInterval `currentInterval` will be incremented to this
      * @param { integer } incrementByFactorOf `currentInterval` is incremented by this factor
      * @param { boolean } lazyStart Configure if timer is initialized on instantiation or lazily
      */
    constructor({ callback, startingInterval, maxInterval, incrementByFactorOf, lazyStart }) {
      this.cfg = {
        callback,
        startingInterval,
        maxInterval,
        incrementByFactorOf,
        lazyStart,
      };

      this.state = {
        intervalId: null,
        currentInterval: startingInterval,
        pageVisibility: 'visible',
      };

      this.initInterval();
    }
    /* public */

    start() {
      const cfg = this.cfg;
      const state = this.state;

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

    // start a timer, using the existing interval
    resume() {
      this.stopTimer(); // stop exsiting timer, in case timer was not previously stopped
      this.start();
    }

    destroy() {
      this.cancel();
      $(document).off('visibilitychange').off('page:before-unload');
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
      $(document)
        .off('visibilitychange').on('visibilitychange', (e) => {
          this.state.pageVisibility = e.target.visibilityState;
          this.handleVisibilityChange();
        });
    }

    initPageUnloadHandling() {
      // prevent interval continuing after page change, when kept in cache by Turbolinks
      $(document).on('page:before-unload', () => this.cancel());
    }

    handleVisibilityChange() {
      const state = this.state;

      const intervalAction = state.pageVisibility === 'hidden' ? this.cancel : this.resume;

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
      let nextInterval = currentInterval * cfg.incrementByFactorOf;

      if (nextInterval > cfg.maxInterval) {
        nextInterval = cfg.maxInterval;
      }

      this.setCurrentInterval(nextInterval);
    }

    stopTimer() {
      const state = this.state;

      state.intervalId = window.clearInterval(state.intervalId);
    }
  }
  gl.SmartInterval = SmartInterval;
})(window.gl || (window.gl = {}));
