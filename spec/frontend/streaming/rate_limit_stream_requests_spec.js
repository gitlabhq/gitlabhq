import waitForPromises from 'helpers/wait_for_promises';
import { rateLimitStreamRequests } from '~/streaming/rate_limit_stream_requests';

describe('rateLimitStreamRequests', () => {
  const encoder = new TextEncoder('utf-8');
  const createStreamResponse = (content = 'foo') =>
    new ReadableStream({
      pull(controller) {
        controller.enqueue(encoder.encode(content));
        controller.close();
      },
    });

  const createFactory = (content) => {
    return jest.fn(() => {
      return Promise.resolve(createStreamResponse(content));
    });
  };

  it('does nothing for zero total requests', () => {
    const factory = jest.fn();
    const requests = rateLimitStreamRequests({
      factory,
      total: 0,
    });
    expect(factory).toHaveBeenCalledTimes(0);
    expect(requests.length).toBe(0);
  });

  it('does not exceed total requests', () => {
    const factory = createFactory();
    const requests = rateLimitStreamRequests({
      factory,
      immediateCount: 100,
      maxConcurrentRequests: 100,
      total: 2,
    });
    expect(factory).toHaveBeenCalledTimes(2);
    expect(requests.length).toBe(2);
  });

  it('creates immediate requests', () => {
    const factory = createFactory();
    const requests = rateLimitStreamRequests({
      factory,
      maxConcurrentRequests: 2,
      total: 2,
    });
    expect(factory).toHaveBeenCalledTimes(2);
    expect(requests.length).toBe(2);
  });

  it('returns correct values', async () => {
    const fixture = 'foobar';
    const factory = createFactory(fixture);
    const requests = rateLimitStreamRequests({
      factory,
      maxConcurrentRequests: 2,
      total: 2,
    });

    const decoder = new TextDecoder('utf-8');
    let result = '';
    for await (const stream of requests) {
      await stream.pipeTo(
        new WritableStream({
          // eslint-disable-next-line no-loop-func
          write(content) {
            result += decoder.decode(content);
          },
        }),
      );
    }

    expect(result).toBe(fixture + fixture);
  });

  it('delays rate limited requests', async () => {
    const factory = createFactory();
    const requests = rateLimitStreamRequests({
      factory,
      maxConcurrentRequests: 2,
      total: 3,
    });
    expect(factory).toHaveBeenCalledTimes(2);
    expect(requests.length).toBe(3);

    await waitForPromises();

    expect(factory).toHaveBeenCalledTimes(3);
  });

  it('runs next request after previous has been fulfilled', async () => {
    let res;
    const factory = jest
      .fn()
      .mockImplementationOnce(
        () =>
          new Promise((resolve) => {
            res = resolve;
          }),
      )
      .mockImplementationOnce(() => Promise.resolve(createStreamResponse()));
    const requests = rateLimitStreamRequests({
      factory,
      maxConcurrentRequests: 1,
      total: 2,
    });
    expect(factory).toHaveBeenCalledTimes(1);
    expect(requests.length).toBe(2);

    await waitForPromises();

    expect(factory).toHaveBeenCalledTimes(1);

    res(createStreamResponse());

    await waitForPromises();

    expect(factory).toHaveBeenCalledTimes(2);
  });

  it('uses timer to schedule next request', async () => {
    let res;
    const factory = jest
      .fn()
      .mockImplementationOnce(
        () =>
          new Promise((resolve) => {
            res = resolve;
          }),
      )
      .mockImplementationOnce(() => Promise.resolve(createStreamResponse()));
    const requests = rateLimitStreamRequests({
      factory,
      immediateCount: 1,
      maxConcurrentRequests: 2,
      total: 2,
      timeout: 9999,
    });
    expect(factory).toHaveBeenCalledTimes(1);
    expect(requests.length).toBe(2);

    await waitForPromises();

    expect(factory).toHaveBeenCalledTimes(1);

    jest.runAllTimers();

    await waitForPromises();

    expect(factory).toHaveBeenCalledTimes(2);
    res(createStreamResponse());
  });
});
