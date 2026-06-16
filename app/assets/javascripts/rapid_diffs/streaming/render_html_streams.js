import { renderHtmlStreams as renderHtmlStreamsBase } from '~/streaming/render_html_streams';
import { fixWebComponentsStreamingOnSafari } from '~/rapid_diffs/app/quirks/safari_fix';

export const renderHtmlStreams = (streamPromises, element, config) => {
  const cleanup = fixWebComponentsStreamingOnSafari(element);
  return renderHtmlStreamsBase(streamPromises, element, config).finally(cleanup);
};
