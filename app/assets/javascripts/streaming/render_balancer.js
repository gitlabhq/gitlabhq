export class RenderBalancer {
  previousTimestamp = undefined;

  constructor({ increase, decrease, highFrameTime, lowFrameTime }) {
    this.increase = increase;
    this.decrease = decrease;
    this.highFrameTime = highFrameTime;
    this.lowFrameTime = lowFrameTime;
  }

  render(fn) {
    return new Promise((resolve) => {
      const callback = (timestamp) => {
        this.throttle(timestamp);
        if (fn()) requestAnimationFrame(callback);
        else resolve();
      };
      requestAnimationFrame(callback);
    });
  }

  throttle(timestamp) {
    const { previousTimestamp } = this;
    this.previousTimestamp = timestamp;
    if (previousTimestamp === undefined) return;

    const duration = Math.round(timestamp - previousTimestamp);
    if (!duration) return;

    if (duration >= this.highFrameTime) {
      this.decrease();
    } else if (duration < this.lowFrameTime) {
      this.increase();
    }
  }
}
