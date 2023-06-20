import waitForPromises from 'helpers/wait_for_promises';
import { renderBlamePageStreams } from '~/blame/streaming';
import { setHTMLFixture } from 'helpers/fixtures';
import { renderHtmlStreams } from '~/streaming/render_html_streams';
import { rateLimitStreamRequests } from '~/streaming/rate_limit_stream_requests';
import { handleStreamedAnchorLink } from '~/streaming/handle_streamed_anchor_link';
import { handleStreamedRelativeTimestamps } from '~/streaming/handle_streamed_relative_timestamps';
import { toPolyfillReadable } from '~/streaming/polyfills';
import { createAlert } from '~/alert';

jest.mock('~/streaming/render_html_streams');
jest.mock('~/streaming/rate_limit_stream_requests');
jest.mock('~/streaming/handle_streamed_anchor_link');
jest.mock('~/streaming/handle_streamed_relative_timestamps');
jest.mock('~/streaming/polyfills');
jest.mock('~/sentry');
jest.mock('~/alert');

global.fetch = jest.fn();

describe('renderBlamePageStreams', () => {
  let stopAnchor;
  let stopTimetamps;
  const PAGES_URL = 'https://example.com/';
  const findStreamContainer = () => document.querySelector('#blame-stream-container');
  const findStreamLoadingIndicator = () => document.querySelector('#blame-stream-loading');

  const setupHtml = (totalExtraPages = 0) => {
    setHTMLFixture(`
      <div id="blob-content-holder"
        data-total-extra-pages="${totalExtraPages}"
        data-pages-url="${PAGES_URL}"
      ></div>
      <div id="blame-stream-container"></div>
      <div id="blame-stream-loading"></div>
    `);
  };

  handleStreamedAnchorLink.mockImplementation(() => stopAnchor);
  handleStreamedRelativeTimestamps.mockImplementation(() => Promise.resolve(stopTimetamps));
  rateLimitStreamRequests.mockImplementation(({ factory, total }) => {
    return Array.from({ length: total }, (_, i) => {
      return Promise.resolve(factory(i));
    });
  });
  toPolyfillReadable.mockImplementation((obj) => obj);

  beforeEach(() => {
    stopAnchor = jest.fn();
    stopTimetamps = jest.fn();
    fetch.mockClear();
  });

  it('does nothing for an empty page', async () => {
    await renderBlamePageStreams();

    expect(handleStreamedAnchorLink).not.toHaveBeenCalled();
    expect(handleStreamedRelativeTimestamps).not.toHaveBeenCalled();
    expect(renderHtmlStreams).not.toHaveBeenCalled();
  });

  it('renders a single stream', async () => {
    let res;
    const stream = new Promise((resolve) => {
      res = resolve;
    });
    renderHtmlStreams.mockImplementationOnce(() => stream);
    setupHtml();

    renderBlamePageStreams(stream);

    expect(handleStreamedAnchorLink).toHaveBeenCalledTimes(1);
    expect(handleStreamedRelativeTimestamps).toHaveBeenCalledTimes(1);
    expect(stopAnchor).toHaveBeenCalledTimes(0);
    expect(stopTimetamps).toHaveBeenCalledTimes(0);
    expect(renderHtmlStreams).toHaveBeenCalledWith([stream], findStreamContainer());
    expect(findStreamLoadingIndicator()).not.toBe(null);

    res();
    await waitForPromises();

    expect(stopAnchor).toHaveBeenCalledTimes(1);
    expect(stopTimetamps).toHaveBeenCalledTimes(1);
    expect(findStreamLoadingIndicator()).toBe(null);
  });

  it('renders rest of the streams', async () => {
    const stream = Promise.resolve();
    const stream2 = Promise.resolve({ body: null });
    fetch.mockImplementationOnce(() => stream2);
    setupHtml(1);

    await renderBlamePageStreams(stream);

    expect(fetch.mock.calls[0][0].toString()).toBe(`${PAGES_URL}?page=3`);
    expect(renderHtmlStreams).toHaveBeenCalledWith([stream, stream2], findStreamContainer());
  });

  it('shows an error message when failed', async () => {
    const stream = Promise.resolve();
    const error = new Error();
    renderHtmlStreams.mockImplementationOnce(() => Promise.reject(error));
    setupHtml();

    try {
      await renderBlamePageStreams(stream);
    } catch (err) {
      expect(err).toBe(error);
    }

    expect(createAlert).toHaveBeenCalledWith({
      message: 'Blame could not be loaded as a single page.',
      primaryButton: {
        text: 'View blame as separate pages',
        clickHandler: expect.any(Function),
      },
    });
  });
});
