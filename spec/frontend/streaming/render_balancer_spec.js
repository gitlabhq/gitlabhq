import { RenderBalancer } from '~/streaming/render_balancer';

const HIGH_FRAME_TIME = 100;
const LOW_FRAME_TIME = 10;

describe('RenderBalancer', () => {
  let increase;
  let decrease;
  let workDuration;
  let tasks; // scheduled callbacks (postTask or rAF), drained by flush()

  const createBalancer = () => {
    increase = jest.fn();
    decrease = jest.fn();
    return new RenderBalancer({
      highFrameTime: HIGH_FRAME_TIME,
      lowFrameTime: LOW_FRAME_TIME,
      increase,
      decrease,
    });
  };

  const flush = (limit = 100) => {
    for (let i = 0; tasks.length && i < limit; i += 1) tasks.shift()();
  };

  const renderTimes = (times) => {
    const balancer = createBalancer();
    let counter = 0;
    const promise = balancer.render(() => {
      if (counter === times) return false;
      counter += 1;
      return true;
    });
    flush();
    return promise.then(() => counter);
  };

  const useScheduler = () => {
    const original = window.scheduler;
    window.scheduler = {
      postTask: jest.fn((callback, { signal } = {}) => {
        const promise = new Promise((_resolve, reject) => {
          signal?.addEventListener(
            'abort',
            () => reject(new DOMException('aborted', 'AbortError')),
            {
              once: true,
            },
          );
        });
        tasks.push(callback);
        return promise;
      }),
    };
    return () => {
      if (original === undefined) delete window.scheduler;
      else window.scheduler = original;
    };
  };

  const useRaf = () => {
    const original = window.scheduler;
    delete window.scheduler;
    jest.spyOn(window, 'requestAnimationFrame').mockImplementation((callback) => {
      tasks.push(callback);
    });
    return () => {
      window.requestAnimationFrame.mockRestore();
      if (original !== undefined) window.scheduler = original;
    };
  };

  beforeEach(() => {
    tasks = [];
    workDuration = (HIGH_FRAME_TIME + LOW_FRAME_TIME) / 2; // neutral band
    let now = 0;
    // each iteration reads performance.now() twice, so advancing by workDuration
    // on every read makes one rendered step measure exactly workDuration
    jest.spyOn(performance, 'now').mockImplementation(() => {
      const value = now;
      now += workDuration;
      return value;
    });
  });

  afterEach(() => {
    performance.now.mockRestore();
  });

  // The render loop is identical for both backends; only the scheduling primitive differs.
  describe.each([
    ['the Scheduler API', useScheduler],
    ['requestAnimationFrame', useRaf],
  ])('driven by %s', (_label, install) => {
    let restore;

    beforeEach(() => {
      restore = install();
    });

    afterEach(() => {
      restore();
    });

    it('renders in a loop until the callback returns false', async () => {
      expect(await renderTimes(5)).toBe(5);
    });

    it('decreases the size when work exceeds the high frame time', async () => {
      workDuration = HIGH_FRAME_TIME * 2;
      await renderTimes(3);
      expect(decrease).toHaveBeenCalled();
      expect(increase).not.toHaveBeenCalled();
    });

    it('increases the size when work stays under the low frame time', async () => {
      workDuration = LOW_FRAME_TIME - 1;
      await renderTimes(3);
      expect(increase).toHaveBeenCalled();
      expect(decrease).not.toHaveBeenCalled();
    });

    it('rejects when the render callback throws', async () => {
      const balancer = createBalancer();
      const error = new Error('boom');
      const promise = balancer.render(() => {
        throw error;
      });
      flush();
      await expect(promise).rejects.toBe(error);
    });

    it('stops rendering after abort()', async () => {
      const balancer = createBalancer();
      const callback = jest.fn(() => true);
      const promise = balancer.render(callback);

      flush(1); // first iteration schedules a follow-up
      expect(callback).toHaveBeenCalledTimes(1);

      balancer.abort();
      flush();
      await promise;

      expect(callback).toHaveBeenCalledTimes(1);
    });
  });

  describe('scheduling primitive', () => {
    it('posts user-visible tasks and aborts them via the signal', () => {
      const restore = useScheduler();
      const balancer = createBalancer();

      balancer.render(() => true);
      const [, options] = window.scheduler.postTask.mock.calls[0];
      expect(options.priority).toBe('user-visible');

      balancer.abort();
      expect(options.signal.aborted).toBe(true);

      restore();
    });

    it('falls back to requestAnimationFrame when the Scheduler API is unavailable', async () => {
      const restore = useRaf();
      const balancer = createBalancer();

      const promise = balancer.render(() => false);
      flush();
      await promise;

      expect(window.requestAnimationFrame).toHaveBeenCalled();
      restore();
    });
  });
});
