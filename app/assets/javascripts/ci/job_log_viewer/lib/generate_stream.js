import Scanner from './scanner';

/**
 * Turns a fetch stream into an async iterable.
 *
 * Could be removed if Chrome implements:
 * https://issues.chromium.org/issues/40612900
 */
async function* getIterableFileStream(path) {
  const response = await fetch(path);
  const reader = response.body.getReader();

  while (true) {
    // eslint-disable-next-line no-await-in-loop
    const { done, value } = await reader.read();
    if (done) break;
    yield value;
  }
}

/**
 * Obtains lines as an async iterable
 * from a binary stream.
 */
async function* getLogStreamLines(stream) {
  const textDecoder = new TextDecoder();

  let chunkRemainder = '';

  for await (const chunk of stream) {
    const decodedChunk = textDecoder.decode(chunk);
    const lines = decodedChunk.split('\n');

    lines[0] = chunkRemainder + lines[0];
    chunkRemainder = lines.pop() || '';

    for (const line of lines) {
      yield line;
    }
  }

  yield chunkRemainder;
}

/**
 * Fetches a raw log and returns a promise with
 * the entire log as an array the can be rendered.
 */
export async function fetchLogLines(path) {
  const iterableStream = getIterableFileStream(path);
  const lines = getLogStreamLines(iterableStream);

  const res = [];
  const scanner = new Scanner();

  for await (const line of lines) {
    const scanned = scanner.scan(line);

    if (scanned) {
      if (scanned.append) {
        const last = res[res.length - 1];

        last.content = [...last.content, ...scanned.content];
        last.timestamp = scanned.timestamp; // time is updated by most recent line

        res[res.length - 1] = last;
      } else {
        res.push(scanned);
      }
    }
  }

  return res;
}
