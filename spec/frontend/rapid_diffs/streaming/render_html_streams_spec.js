import { renderHtmlStreams } from '~/rapid_diffs/streaming/render_html_streams';
import { renderHtmlStreams as renderHtmlStreamsBase } from '~/streaming/render_html_streams';
import { fixWebComponentsStreamingOnSafari } from '~/rapid_diffs/app/quirks/safari_fix';

jest.mock('~/streaming/render_html_streams');
jest.mock('~/rapid_diffs/app/quirks/safari_fix');

describe('Rapid Diffs renderHtmlStreams', () => {
  const streams = [{}];
  const element = document.createElement('div');
  const config = { signal: {} };

  it('sets up the Safari fix, renders the streams and cleans up afterwards', async () => {
    const cleanup = jest.fn();
    const result = Symbol('result');
    fixWebComponentsStreamingOnSafari.mockReturnValue(cleanup);
    renderHtmlStreamsBase.mockResolvedValue(result);

    await expect(renderHtmlStreams(streams, element, config)).resolves.toBe(result);

    expect(fixWebComponentsStreamingOnSafari).toHaveBeenCalledWith(element);
    expect(renderHtmlStreamsBase).toHaveBeenCalledWith(streams, element, config);
    expect(cleanup).toHaveBeenCalled();
  });

  it('cleans up even when streaming throws', async () => {
    const cleanup = jest.fn();
    const error = new Error('boom');
    fixWebComponentsStreamingOnSafari.mockReturnValue(cleanup);
    renderHtmlStreamsBase.mockRejectedValue(error);

    await expect(renderHtmlStreams(streams, element, config)).rejects.toBe(error);

    expect(cleanup).toHaveBeenCalled();
  });
});
