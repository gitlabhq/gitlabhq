import { HtmlStream } from '~/streaming/html_stream';
import { ChunkWriter } from '~/streaming/chunk_writer';

jest.mock('~/streaming/chunk_writer');

describe('HtmlStream', () => {
  let write;
  let close;
  let streamingElement;

  beforeEach(() => {
    write = jest.fn();
    close = jest.fn();
    jest.spyOn(Document.prototype, 'write').mockImplementation(write);
    jest.spyOn(Document.prototype, 'close').mockImplementation(close);
    jest.spyOn(Document.prototype, 'querySelector').mockImplementation(() => {
      streamingElement = document.createElement('div');
      return streamingElement;
    });
  });

  it('attaches to original document', () => {
    // eslint-disable-next-line no-new
    new HtmlStream(document.body);
    expect(document.body.contains(streamingElement)).toBe(true);
  });

  it('can write to a document', () => {
    const htmlStream = new HtmlStream(document.body);
    htmlStream.write('foo');
    htmlStream.close();
    expect(write.mock.calls).toEqual([['<streaming-element>'], ['foo'], ['</streaming-element>']]);
    expect(close).toHaveBeenCalledTimes(1);
  });

  it('returns chunked writer', () => {
    const htmlStream = new HtmlStream(document.body).withChunkWriter();
    expect(htmlStream).toBeInstanceOf(ChunkWriter);
  });

  it('closes on abort', () => {
    const htmlStream = new HtmlStream(document.body);
    htmlStream.abort();
    expect(close).toHaveBeenCalled();
  });
});
