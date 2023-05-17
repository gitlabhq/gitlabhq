import { ChunkWriter } from '~/streaming/chunk_writer';

export class HtmlStream {
  constructor(element) {
    const streamDocument = document.implementation.createHTMLDocument('stream');

    streamDocument.open();
    streamDocument.write('<streaming-element>');

    const virtualStreamingElement = streamDocument.querySelector('streaming-element');
    element.appendChild(document.adoptNode(virtualStreamingElement));

    this.streamDocument = streamDocument;
  }

  withChunkWriter(config) {
    return new ChunkWriter(this, config);
  }

  write(chunk) {
    // eslint-disable-next-line no-unsanitized/method
    this.streamDocument.write(chunk);
  }

  close() {
    this.streamDocument.write('</streaming-element>');
    this.streamDocument.close();
  }

  abort() {
    this.streamDocument.close();
  }
}
