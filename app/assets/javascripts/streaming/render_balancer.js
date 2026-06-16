const supportsScheduler = () =>
  typeof window !== 'undefined' &&
  'scheduler' in window &&
  typeof window.scheduler.postTask === 'function';

export class RenderBalancer {
  #abortController = new AbortController();
  #schedule;

  constructor({ increase, decrease, highFrameTime, lowFrameTime }) {
    this.increase = increase;
    this.decrease = decrease;
    this.highFrameTime = highFrameTime;
    this.lowFrameTime = lowFrameTime;
    this.#schedule = supportsScheduler() ? this.#scheduleTask : this.#scheduleFrame;
  }

  render(fn) {
    return new Promise((resolve, reject) => {
      const tick = () => {
        if (this.#abortController.signal.aborted) {
          resolve();
          return;
        }
        try {
          if (this.#step(fn)) this.#schedule(tick);
          else resolve();
        } catch (error) {
          reject(error);
        }
      };
      this.#schedule(tick);
    });
  }

  #scheduleTask(callback) {
    window.scheduler
      .postTask(callback, { priority: 'user-visible', signal: this.#abortController.signal })
      .catch(() => {}); // postTask rejects once the signal aborts
  }

  // eslint-disable-next-line class-methods-use-this
  #scheduleFrame(callback) {
    requestAnimationFrame(callback);
  }

  #step(fn) {
    const start = performance.now();
    const shouldContinue = fn();
    this.#balance(performance.now() - start);
    return shouldContinue;
  }

  #balance(duration) {
    if (duration >= this.highFrameTime) {
      this.decrease();
    } else if (duration < this.lowFrameTime) {
      this.increase();
    }
  }

  abort() {
    this.#abortController.abort();
  }
}
