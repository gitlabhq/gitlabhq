export default class TaskQueue {
  #queue = [];
  #runningTasks = 0;
  #concurrencyLimit;

  constructor(concurrencyLimit = 1) {
    this.#concurrencyLimit = concurrencyLimit;
  }

  enqueue(task) {
    return new Promise((resolve, reject) => {
      this.#queue.push(async () => {
        try {
          resolve(await task());
        } catch (e) {
          reject(e);
        } finally {
          this.#runningTasks -= 1;
          this.processQueue();
        }
      });

      this.processQueue();
    });
  }

  async processQueue() {
    while (this.#runningTasks < this.#concurrencyLimit && this.#queue.length > 0) {
      this.#runningTasks += 1;
      const task = this.#queue.shift();

      // We don't await here to allow concurrent execution
      task();
    }
  }

  clear() {
    this.#queue = [];
    this.#runningTasks = 0;
  }

  get size() {
    return this.#queue.length;
  }

  get isEmpty() {
    return this.#queue.length === 0;
  }

  get concurrencyLimit() {
    return this.#concurrencyLimit;
  }
}
