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
  });

  describe('clear', () => {
    it('clears the queue and resets running tasks', () => {
      taskQueue.enqueue(() => sleep(0.01));
      taskQueue.enqueue(() => sleep(0.01));
      taskQueue.enqueue(() => sleep(0.01));
      taskQueue.enqueue(() => sleep(0.01));

      // two have begun executing and two pending
      expect(taskQueue.size).toBe(2);

      taskQueue.clear();

      expect(taskQueue.size).toBe(0);
      expect(taskQueue.isEmpty).toBe(true);
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
