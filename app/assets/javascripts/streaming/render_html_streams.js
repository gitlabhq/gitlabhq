import { HtmlStream } from '~/streaming/html_stream';

async function pipeStreams(domWriter, streamPromises) {
  try {
    for await (const stream of streamPromises.slice(0, -1)) {
      await stream.pipeTo(domWriter, { preventClose: true });
    }
    const stream = await streamPromises[streamPromises.length - 1];
    await stream.pipeTo(domWriter);
  } catch (error) {
    domWriter.abort(error);
  }
}

// this function (and the rest of the pipeline) expects polyfilled streams
// do not pass native streams here unless our browser support allows for it
// TODO: remove this notice when our WebStreams API support reaches 100%
export function renderHtmlStreams(streamPromises, element, config) {
  if (streamPromises.length === 0) return Promise.resolve();

  const chunkedHtmlStream = new HtmlStream(element).withChunkWriter(config);

  return new Promise((resolve, reject) => {
    const domWriter = new WritableStream({
      write(chunk) {
        return chunkedHtmlStream.write(chunk);
      },
      close() {
        chunkedHtmlStream.close();
        resolve();
      },
      abort(error) {
        chunkedHtmlStream.abort();
        reject(error);
      },
    });

    pipeStreams(domWriter, streamPromises);
  });
}
