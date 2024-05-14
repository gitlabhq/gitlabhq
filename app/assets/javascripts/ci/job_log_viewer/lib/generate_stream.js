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
 * Obtains stream lines as an async iterable
 *
 * NOTE: This code wrongly assumes each chunk has no cut lines.
 * Large logs may contain several chunk and this may effectively
 * split some lines in two.
 */
async function* getLogStreamLines(stream) {
  const textDecoder = new TextDecoder();

  for await (const chunk of stream) {
    const decodedChunk = textDecoder.decode(chunk);
    const lines = decodedChunk.split('\n');
    for (const line of lines) {
      if (line.trim() !== '') {
        yield {
          text: line,
        };
      }
    }
  }
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
    const scanned = scanner.scan(line.text);
    res.push(scanned);
  }

  return res;
}
