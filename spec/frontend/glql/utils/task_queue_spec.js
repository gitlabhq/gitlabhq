import TaskQueue from '~/glql/utils/task_queue';

const sleep = (s) =>
  new Promise((resolve) => {
    setTimeout(resolve, s * 1000);
  });

describe('TaskQueue', () => {
  let taskQueue;

  beforeEach(() => {
    taskQueue = new TaskQueue(2);
    jest.useRealTimers();
  });

  afterEach(() => {
    jest.useFakeTimers();
  });

  describe('constructor', () => {
    it('sets the default concurrency limit to 1', () => {
      const defaultQueue = new TaskQueue();
      expect(defaultQueue.concurrencyLimit).toBe(1);
    });

    it('sets the specified concurrency limit', () => {
      expect(taskQueue.concurrencyLimit).toBe(2);
    });
  });

  describe('enqueue', () => {
    it('executes tasks concurrently up to the concurrency limit', async () => {
      const executionOrder = [];

      const task1 = jest.fn().mockImplementation(async () => {
        await sleep(0.1);
        executionOrder.push(1);
      });

      const task2 = jest.fn().mockImplementation(async () => {
        await sleep(0.05);
        executionOrder.push(2);
      });

      const task3 = jest.fn().mockImplementation(() => {
        executionOrder.push(3);
      });

      await Promise.all([
        taskQueue.enqueue(task1),
        taskQueue.enqueue(task2),
        taskQueue.enqueue(task3),
      ]);

      expect(executionOrder).toEqual([2, 3, 1]);
      expect(task1).toHaveBeenCalledTimes(1);
      expect(task2).toHaveBeenCalledTimes(1);
      expect(task3).toHaveBeenCalledTimes(1);
    });

    it('handles errors in tasks', async () => {
      const successTask = jest.fn().mockResolvedValue('success');
      const errorTask = jest.fn().mockRejectedValue(new Error('Task failed'));

      const successPromise = taskQueue.enqueue(successTask);
      const errorPromise = taskQueue.enqueue(errorTask);

      await expect(successPromise).resolves.toBe('success');
      await expect(errorPromise).rejects.toThrow('Task failed');
    });

    describe('when a waiting task is aborted', () => {
      let releaseRunning;
      let runningTasks;
      let abortedTask;
      let abortedPromise;
      let laterTask;
      let laterPromise;

      beforeEach(() => {
        const running = new Promise((resolve) => {
          releaseRunning = resolve;
        });
        runningTasks = [jest.fn(() => running), jest.fn(() => running)];
        abortedTask = jest.fn().mockResolvedValue('aborted');
        laterTask = jest.fn().mockResolvedValue('later');

        const controller = new AbortController();

        runningTasks.forEach((task) => taskQueue.enqueue(task));
        abortedPromise = taskQueue.enqueue(abortedTask, { signal: controller.signal });
        laterPromise = taskQueue.enqueue(laterTask);
        // Only the first example awaits the rejection; the others must not leave it unhandled.
        abortedPromise.catch(() => {});

        controller.abort(new Error('Discarded'));
        releaseRunning();
      });

      it('rejects it with the abort reason without running it', async () => {
        await expect(abortedPromise).rejects.toThrow('Discarded');
        expect(abortedTask).not.toHaveBeenCalled();
      });

      it('still runs the tasks queued after it', async () => {
        await expect(laterPromise).resolves.toBe('later');
        expect(laterTask).toHaveBeenCalledTimes(1);
      });

      it('does not count it against the concurrency limit', async () => {
        await laterPromise;

        const next = [jest.fn(() => new Promise(() => {})), jest.fn(() => new Promise(() => {}))];
        next.forEach((task) => taskQueue.enqueue(task));

        expect(next[0]).toHaveBeenCalledTimes(1);
        expect(next[1]).toHaveBeenCalledTimes(1);
        expect(taskQueue.size).toBe(0);
      });
    });

    describe('when a running task is aborted', () => {
      it('runs it to completion', async () => {
        const controller = new AbortController();
        const promise = taskQueue.enqueue(
          () => {
            controller.abort();
            return Promise.resolve('done');
          },
          { signal: controller.signal },
        );

        await expect(promise).resolves.toBe('done');
      });
    });
  });

  describe('size and isEmpty', () => {
    it('returns correct size and isEmpty values', () => {
      expect(taskQueue.size).toBe(0);
      expect(taskQueue.isEmpty).toBe(true);

      taskQueue.enqueue(() => sleep(0.01));
      taskQueue.enqueue(() => sleep(0.01));
      taskQueue.enqueue(() => sleep(0.01));

      // two have begun executing and one pending
      expect(taskQueue.size).toBe(1);
      expect(taskQueue.isEmpty).toBe(false);
    });
  });
});
