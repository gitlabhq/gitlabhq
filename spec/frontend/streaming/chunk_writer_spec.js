import { throttle } from 'lodash';
import { ChunkWriter } from '~/streaming/chunk_writer';
import { RenderBalancer } from '~/streaming/render_balancer';

jest.mock('~/streaming/render_balancer');
jest.mock('lodash/throttle', () => jest.fn());

describe('ChunkWriter', () => {
  let accumulator = '';
  let write;
  let close;
  let abort;
  let config;
  let render;
  let cancelTimer;
  let runTimer;

  const createChunk = (text) => {
    const encoder = new TextEncoder();
    return encoder.encode(text);
  };

  const createHtmlStream = () => {
    write = jest.fn((part) => {
      accumulator += part;
    });
    close = jest.fn();
    abort = jest.fn();
    return {
      write,
      close,
      abort,
    };
  };

  const createWriter = () => {
    return new ChunkWriter(createHtmlStream(), config);
  };

  const pushChunks = (...chunks) => {
    const writer = createWriter();
    chunks.forEach((chunk) => {
      writer.write(createChunk(chunk));
    });
    writer.close();
  };

  afterAll(() => {
    global.JEST_DEBOUNCE_THROTTLE_TIMEOUT = undefined;
  });

  beforeEach(() => {
    global.JEST_DEBOUNCE_THROTTLE_TIMEOUT = 100;
    accumulator = '';
    config = undefined;
    render = jest.fn((cb) => {
      while (cb()) {
        // render until 'false'
      }
    });
    RenderBalancer.mockImplementation(() => ({ render }));
    cancelTimer = jest.fn();
    throttle.mockImplementation((fn) => {
      const promise = new Promise((resolve) => {
        runTimer = () => {
          fn();
          resolve();
        };
      });
      promise.cancel = cancelTimer;
      const result = () => promise;
      result.cancel = cancelTimer;
      return result;
    });
  });

  afterEach(() => {
    throttle.mockReset();
  });

  describe('when chunk length must be "1"', () => {
    beforeEach(() => {
      config = { minChunkSize: 1, maxChunkSize: 1 };
    });

    it('splits big chunks into smaller ones', () => {
      const text = 'foobar';
      pushChunks(text);
      expect(accumulator).toBe(text);
      expect(write).toHaveBeenCalledTimes(text.length);
    });

    it('handles small emoji chunks', () => {
      const text = 'foo👀bar👨‍👩‍👧baz👧👧🏻👧🏼👧🏽👧🏾👧🏿';
      pushChunks(text);
      expect(accumulator).toBe(text);
      expect(write).toHaveBeenCalledTimes(createChunk(text).length);
    });
  });

  describe('when chunk length must not be lower than "5" and exceed "10"', () => {
    beforeEach(() => {
      config = { minChunkSize: 5, maxChunkSize: 10 };
    });

    it('joins small chunks', () => {
      const text = '12345';
      pushChunks(...text.split(''));
      expect(accumulator).toBe(text);
      expect(write).toHaveBeenCalledTimes(1);
      expect(close).toHaveBeenCalledTimes(1);
    });

    it('handles overflow with small chunks', () => {
      const text = '123456789';
      pushChunks(...text.split(''));
      expect(accumulator).toBe(text);
      expect(write).toHaveBeenCalledTimes(2);
      expect(close).toHaveBeenCalledTimes(1);
    });

    it('calls flush on small chunks', () => {
      global.JEST_DEBOUNCE_THROTTLE_TIMEOUT = undefined;
      const flushAccumulator = jest.spyOn(ChunkWriter.prototype, 'flushAccumulator');
      const text = '1';
      pushChunks(text);
      runTimer();
      expect(accumulator).toBe(text);
      expect(flushAccumulator).toHaveBeenCalledTimes(1);
    });

    it('calls flush on large chunks', () => {
      const flushAccumulator = jest.spyOn(ChunkWriter.prototype, 'flushAccumulator');
      const text = '1234567890123';
      const writer = createWriter();
      writer.write(createChunk(text));
      runTimer();
      expect(accumulator).toBe(text);
      expect(flushAccumulator).toHaveBeenCalledTimes(1);
    });
  });

  describe('chunk balancing', () => {
    let increase;
    let decrease;
    let renderOnce;

    beforeEach(() => {
      render = jest.fn((cb) => {
        let next = true;
        renderOnce = () => {
          if (!next) return;
          next = cb();
        };
      });
      RenderBalancer.mockImplementation(({ increase: inc, decrease: dec }) => {
        increase = jest.fn(inc);
        decrease = jest.fn(dec);
        return {
          render,
        };
      });
    });

    describe('when frame time exceeds low limit', () => {
      beforeEach(() => {
        config = {
          minChunkSize: 1,
          maxChunkSize: 5,
          balanceRate: 10,
        };
      });

      it('increases chunk size', () => {
        const text = '111222223';
        const writer = createWriter();
        const chunk = createChunk(text);

        writer.write(chunk);

        renderOnce();
        increase();
        renderOnce();
        renderOnce();

        writer.close();

        expect(accumulator).toBe(text);
        expect(write.mock.calls).toMatchObject([['111'], ['22222'], ['3']]);
        expect(close).toHaveBeenCalledTimes(1);
      });
    });

    describe('when frame time exceeds high limit', () => {
      beforeEach(() => {
        config = {
          minChunkSize: 1,
          maxChunkSize: 10,
          balanceRate: 2,
        };
      });

      it('decreases chunk size', () => {
        const text = '1111112223345';
        const writer = createWriter();
        const chunk = createChunk(text);

        writer.write(chunk);

        renderOnce();
        decrease();

        renderOnce();
        decrease();

        renderOnce();
        decrease();

        renderOnce();
        renderOnce();

        writer.close();

        expect(accumulator).toBe(text);
        expect(write.mock.calls).toMatchObject([['111111'], ['222'], ['33'], ['4'], ['5']]);
        expect(close).toHaveBeenCalledTimes(1);
      });
    });
  });

  it('calls abort on htmlStream', () => {
    const writer = createWriter();
    writer.abort();
    expect(abort).toHaveBeenCalledTimes(1);
  });

  it('accumulates chunk with a timeout', () => {
    const text = '111222223';
    config = { minChunkSize: 1000, maxChunkSize: 1000 };
    const writer = createWriter();
    const chunk = createChunk(text);
    writer.write(chunk);
    writer.write(chunk);
    writer.write(chunk);
    runTimer();
    expect(accumulator).toBe(text.repeat(3));
    expect(write.mock.calls).toMatchObject([[text.repeat(3)]]);
    expect(cancelTimer).not.toHaveBeenCalled();
  });

  it('aborts on abort signal', () => {
    const controller = new AbortController();
    config = { signal: controller.signal };
    createWriter().write(createChunk('1234567890'));
    controller.abort();
    expect(abort).toHaveBeenCalledTimes(1);
    expect(write).not.toHaveBeenCalled();
  });
});
