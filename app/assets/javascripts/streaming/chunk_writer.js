import { throttle } from 'lodash';
import { RenderBalancer } from '~/streaming/render_balancer';
import {
  BALANCE_RATE,
  HIGH_FRAME_TIME,
  LOW_FRAME_TIME,
  MAX_CHUNK_SIZE,
  MIN_CHUNK_SIZE,
  TIMEOUT,
} from '~/streaming/constants';

const defaultConfig = {
  balanceRate: BALANCE_RATE,
  minChunkSize: MIN_CHUNK_SIZE,
  maxChunkSize: MAX_CHUNK_SIZE,
  lowFrameTime: LOW_FRAME_TIME,
  highFrameTime: HIGH_FRAME_TIME,
  timeout: TIMEOUT,
};

function concatUint8Arrays(a, b) {
  const array = new Uint8Array(a.length + b.length);
  array.set(a, 0);
  array.set(b, a.length);
  return array;
}

// This class is used to write chunks with a balanced size
// to avoid blocking main thread for too long.
//
// A chunk can be:
//   1. Too small
//   2. Too large
//   3. Delayed in time
//
// This class resolves all these problems by
//   1. Splitting or concatenating chunks to met the size criteria
//   2. Rendering current chunk buffer immediately if enough time has passed
//
// The size of the chunk is determined by RenderBalancer,
// It measures execution time for each chunk write and adjusts next chunk size.
export class ChunkWriter {
  buffer = null;
  decoder = new TextDecoder('utf-8');
  timeout = null;

  constructor(htmlStream, config) {
    this.htmlStream = htmlStream;

    const {
      balanceRate,
      minChunkSize,
      maxChunkSize,
      lowFrameTime,
      highFrameTime,
      timeout,
      signal,
    } = {
      ...defaultConfig,
      ...config,
    };

    this.registerSignal(signal);

    // ensure we still render chunks over time if the size criteria is not met
    this.scheduleAccumulatorFlush = throttle(this.flushAccumulator.bind(this), timeout);

    const averageSize = Math.round((maxChunkSize + minChunkSize) / 2);
    this.size = Math.max(averageSize, minChunkSize);

    this.balancer = new RenderBalancer({
      lowFrameTime,
      highFrameTime,
      decrease: () => {
        this.size = Math.round(Math.max(this.size / balanceRate, minChunkSize));
      },
      increase: () => {
        this.size = Math.round(Math.min(this.size * balanceRate, maxChunkSize));
      },
    });
  }

  registerSignal(signal) {
    this.cancelAbort = () => {};
    if (!signal) return;
    const abort = this.abort.bind(this);
    this.cancelAbort = () => {
      signal.removeEventListener('abort', abort);
    };
    signal.addEventListener('abort', abort, {
      once: true,
    });
  }

  write(chunk) {
    if (this.buffer) {
      this.buffer = concatUint8Arrays(this.buffer, chunk);
    } else {
      this.buffer = chunk;
    }

    // accumulate chunks until the size is fulfilled
    if (this.size > this.buffer.length) {
      this.scheduleAccumulatorFlush();
      return Promise.resolve();
    }

    this.scheduleAccumulatorFlush.cancel();
    return this.balancedWrite();
  }

  balancedWrite() {
    let cursor = 0;

    return this.balancer.render(() => {
      const chunkPart = this.buffer.subarray(cursor, cursor + this.size);
      // accumulate chunks until the size is fulfilled
      // this is a hot path for the last chunkPart of the chunk
      if (chunkPart.length < this.size) {
        this.buffer = chunkPart;
        this.scheduleAccumulatorFlush();
        return false;
      }

      this.writeToDom(chunkPart);

      cursor += this.size;
      if (cursor >= this.buffer.length) {
        this.buffer = null;
        return false;
      }
      // continue render
      return true;
    });
  }

  writeToDom(chunk, stream = true) {
    // stream: true allows us to split chunks with multi-part words
    const decoded = this.decoder.decode(chunk, { stream });
    this.htmlStream.write(decoded);
  }

  flushAccumulator() {
    if (this.buffer) {
      this.writeToDom(this.buffer);
      this.buffer = null;
    }
  }

  close() {
    this.scheduleAccumulatorFlush.cancel();
    if (this.buffer) {
      // last chunk should have stream: false to indicate the end of the stream
      this.writeToDom(this.buffer, false);
      this.buffer = null;
    }
    this.htmlStream.close();
    this.cancelAbort();
  }

  abort() {
    this.scheduleAccumulatorFlush.cancel();
    this.buffer = null;
    this.htmlStream.abort();
    this.cancelAbort();
  }
}
