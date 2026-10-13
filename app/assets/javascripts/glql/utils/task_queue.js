export default class TaskQueue {
  #queue = [];
  #runningTasks = 0;
  #concurrencyLimit;

  constructor(concurrencyLimit = 1) {
    this.#concurrencyLimit = concurrencyLimit;
  }

  // A task whose `signal` is aborted while it waits is rejected without running. A task that has
  // already started runs to completion, so it keeps its slot for as long as the server works on it.
  // Waiting tasks run lowest `priority` first; equal priorities keep their arrival order.
  enqueue(task, { signal, priority = 0 } = {}) {
    return new Promise((resolve, reject) => {
      const entry = {
        priority,
        signal,
        reject,
        run: async () => {
          try {
            resolve(await task());
          } catch (e) {
            reject(e);
          } finally {
            this.#runningTasks -= 1;
            this.processQueue();
          }
        },
      };
      const index = this.#queue.findIndex((waiting) => waiting.priority > priority);
      this.#queue.splice(index === -1 ? this.#queue.length : index, 0, entry);

      this.processQueue();
    });
  }

  async processQueue() {
    while (this.#runningTasks < this.#concurrencyLimit && this.#queue.length > 0) {
      const { signal, reject, run } = this.#queue.shift();

      if (signal?.aborted) {
        reject(signal.reason);
      } else {
        this.#runningTasks += 1;

        // We don't await here to allow concurrent execution
        run();
      }
    }
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
