import { ReadableStream } from 'node:stream/web';
import { renderHtmlStreams } from '~/streaming/render_html_streams';
import { HtmlStream } from '~/streaming/html_stream';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/streaming/html_stream');
jest.mock('~/streaming/constants', () => {
  return {
    HIGH_FRAME_TIME: 0,
    LOW_FRAME_TIME: 0,
    MAX_CHUNK_SIZE: 1,
    MIN_CHUNK_SIZE: 1,
  };
});

const firstStreamContent = 'foobar';
const secondStreamContent = 'bazqux';

describe('renderHtmlStreams', () => {
  let htmlWriter;
  const encoder = new TextEncoder();
  const createSingleChunkStream = (chunk) => {
    const encoded = encoder.encode(chunk);
    const stream = new ReadableStream({
      pull(controller) {
        controller.enqueue(encoded);
        controller.close();
      },
    });
    return [stream, encoded];
  };

  beforeEach(() => {
    htmlWriter = {
      write: jest.fn(),
      close: jest.fn(),
      abort: jest.fn(),
    };
    jest.spyOn(HtmlStream.prototype, 'withChunkWriter').mockReturnValue(htmlWriter);
  });

  it('renders a single stream', async () => {
    const [stream, encoded] = createSingleChunkStream(firstStreamContent);

    await renderHtmlStreams([Promise.resolve(stream)], document.body);

    expect(htmlWriter.write).toHaveBeenCalledWith(encoded);
    expect(htmlWriter.close).toHaveBeenCalledTimes(1);
  });

  it('renders stream sequence', async () => {
    const [stream1, encoded1] = createSingleChunkStream(firstStreamContent);
    const [stream2, encoded2] = createSingleChunkStream(secondStreamContent);

    await renderHtmlStreams([Promise.resolve(stream1), Promise.resolve(stream2)], document.body);

    expect(htmlWriter.write.mock.calls).toMatchObject([[encoded1], [encoded2]]);
    expect(htmlWriter.close).toHaveBeenCalledTimes(1);
  });

  it("doesn't wait for the whole sequence to resolve before streaming", async () => {
    const [stream1, encoded1] = createSingleChunkStream(firstStreamContent);
    const [stream2, encoded2] = createSingleChunkStream(secondStreamContent);

    let res;
    const delayedStream = new Promise((resolve) => {
      res = resolve;
    });

    renderHtmlStreams([Promise.resolve(stream1), delayedStream], document.body);

    await waitForPromises();

    expect(htmlWriter.write.mock.calls).toMatchObject([[encoded1]]);
    expect(htmlWriter.close).toHaveBeenCalledTimes(0);

    res(stream2);
    await waitForPromises();

    expect(htmlWriter.write.mock.calls).toMatchObject([[encoded1], [encoded2]]);
    expect(htmlWriter.close).toHaveBeenCalledTimes(1);
  });

  it('closes HtmlStream on error', async () => {
    const [stream1] = createSingleChunkStream(firstStreamContent);
    const error = new Error();

    try {
      await renderHtmlStreams([Promise.resolve(stream1), Promise.reject(error)], document.body);
    } catch (err) {
      expect(err).toBe(error);
    }

    expect(htmlWriter.abort).toHaveBeenCalledTimes(1);
  });
});
