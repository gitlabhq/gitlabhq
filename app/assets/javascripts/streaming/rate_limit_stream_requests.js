const consumeReadableStream = (stream) => {
  return new Promise((resolve, reject) => {
    stream.pipeTo(
      new WritableStream({
        close: resolve,
        abort: reject,
      }),
    );
  });
};

const wait = (timeout) =>
  new Promise((resolve) => {
    setTimeout(resolve, timeout);
  });

// this rate-limiting approach is specific to Web Streams
// because streams only resolve when they're fully consumed
// so we need to split each stream into two pieces:
//   one for the rate-limiter (wait for all the bytes to be sent)
//   another for the original consumer
export const rateLimitStreamRequests = ({
  factory,
  total,
  maxConcurrentRequests,
  immediateCount = maxConcurrentRequests,
  timeout = 0,
}) => {
  if (total === 0) return [];

  const unsettled = [];

  const pushUnsettled = (promise) => {
    let res;
    let rej;
    const consume = new Promise((resolve, reject) => {
      res = resolve;
      rej = reject;
    });
    unsettled.push(consume);
    return promise.then((stream) => {
      const [first, second] = stream.tee();
      consumeReadableStream(first)
        // eslint-disable-next-line promise/no-nesting
        .then(() => {
          unsettled.splice(unsettled.indexOf(consume), 1);
          res();
        })
        // eslint-disable-next-line promise/no-nesting
        .catch(rej);
      return second;
    }, rej);
  };

  const immediate = Array.from({ length: Math.min(immediateCount, total) }, (_, i) =>
    pushUnsettled(factory(i)),
  );

  const queue = [];
  const flushQueue = () => {
    const promises =
      unsettled.length > maxConcurrentRequests ? unsettled : [...unsettled, wait(timeout)];
    // errors are handled by the caller
    // eslint-disable-next-line promise/catch-or-return
    Promise.race(promises).then(() => {
      const cb = queue.shift();
      cb?.();
      if (queue.length !== 0) {
        // wait for stream consumer promise to be removed from unsettled
        queueMicrotask(flushQueue);
      }
    });
  };

  const throttled = Array.from({ length: total - immediateCount }, (_, i) => {
    return new Promise((resolve, reject) => {
      queue.push(() => {
        pushUnsettled(factory(i + immediateCount))
          .then(resolve)
          .catch(reject);
      });
    });
  });

  flushQueue();

  return [...immediate, ...throttled];
};
