((global) => {
  class SmartInterval {
    constructor({ name = 'SmartIntervalInstance', callback, high = 120000, low = 15000, increment = 0, delay = 5000, immediate = true, runInBackground = false, runInCache = false }) {
      this.callback = callback;
      this.high = high;
      this.low = low;
      this.delay = delay;
      this.runInBackground = runInBackground;
      this.increment = increment;
      this.immediate = immediate;
      this.name = name;

      this.state = {
        iterations: 0,
        currentInterval: low,
        intervalId: null
      };

      this.init();
    }

    init() {
      if (this.immediate) {
        window.setTimeout(() => {
          this.start();
        }, this.delay);
      }

      if (!this.runInBackground) {
        // cancel interval when tab no longer shown
        const visChangeEventName = `visibilitychange:${this.name}`;
        $(document).off(visChangeEventName).on(visChangeEventName, (e) => {
          const visState = document.visibilityState;
          if (visState === 'hidden') {
            this.pause();
          } else {
            this.restart();
          }
        });
      }

      if (!this.runInCache) {
        // prevent interval continuing after page change, when kept in cache by Turbolinks
        $(document).on('page:before-unload', (e) => {
          this.cancel();
        });
      }
    }

    stopTimer() {
      window.clearInterval(this.state.intervalId);
      this.state.intervalId = null;
    }

    // TODO: Remove after development
    logIteration() {
      const iterations = this.state.iterations++;
      console.log(`interval callback executed -- iterations: ${ iterations } -- current interval: ${ this.state.currentInterval }`);
    }

    /* public methods */

    start() {
      this.state.intervalId = setInterval(() => {
        this.callback();

        this.logIteration();

        if (this.state.currentInterval === this.high) {
          return;
        }

        let nextInterval = this.state.currentInterval + this.increment;

        if (nextInterval > this.high) {
          nextInterval = this.high;
        }

        this.state.currentInterval = nextInterval;
        this.restart();
      }, this.state.currentInterval);
    }

    // cancel the existing timer, setting the currentInterval back to low
    cancel() {
      this.state.currentInterval = this.low;
      this.stopTimer();
    }

    // cancel the existing timer, without setting the currentInterval back to low
    pause() {
      this.stopTimer();
    }

    // start a timer, using the existing interval
    restart() {
      this.stopTimer();
      this.start();
    }
  }

  global.SmartInterval = SmartInterval;
})(window.gl || (window.gl = {}));
