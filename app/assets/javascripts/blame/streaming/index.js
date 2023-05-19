import { renderHtmlStreams } from '~/streaming/render_html_streams';
import { handleStreamedAnchorLink } from '~/streaming/handle_streamed_anchor_link';
import { handleStreamedRelativeTimestamps } from '~/streaming/handle_streamed_relative_timestamps';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { rateLimitStreamRequests } from '~/streaming/rate_limit_stream_requests';
import { toPolyfillReadable } from '~/streaming/polyfills';

export async function renderBlamePageStreams(firstStreamPromise) {
  const element = document.querySelector('#blame-stream-container');

  if (!element || !firstStreamPromise) return;

  const stopAnchorObserver = handleStreamedAnchorLink(element);
  const relativeTimestampsHandler = handleStreamedRelativeTimestamps(element);
  const { dataset } = document.querySelector('#blob-content-holder');
  const totalExtraPages = parseInt(dataset.totalExtraPages, 10);
  const { pagesUrl } = dataset;

  const remainingStreams = rateLimitStreamRequests({
    factory: (index) => {
      const url = new URL(pagesUrl);
      // page numbers start with 1
      // the first page is already rendered in the document
      // the second page is passed with the 'firstStreamPromise'
      url.searchParams.set('page', index + 3);
      return fetch(url).then((response) => toPolyfillReadable(response.body));
    },
    // we don't want to overload gitaly with concurrent requests
    // https://gitlab.com/gitlab-org/gitlab/-/issues/391842#note_1281695095
    // using 5 as a good starting point
    maxConcurrentRequests: 5,
    total: totalExtraPages,
  });

  try {
    await renderHtmlStreams(
      [firstStreamPromise.then(toPolyfillReadable), ...remainingStreams],
      element,
    );
  } catch (error) {
    createAlert({
      message: __('Blame could not be loaded as a single page.'),
      primaryButton: {
        text: __('View blame as separate pages'),
        clickHandler() {
          const newUrl = new URL(window.location);
          newUrl.searchParams.delete('streaming');
          window.location.href = newUrl;
        },
      },
    });
    throw error;
  } finally {
    const stopTimestampObserver = await relativeTimestampsHandler;
    stopTimestampObserver();
    stopAnchorObserver();
    document.querySelector('#blame-stream-loading').remove();
  }
}
