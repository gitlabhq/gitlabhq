import initCommitActions from '~/projects/commit';
import { initCommitBoxInfo } from '~/projects/commit_box/info';
import { renderHtmlStreams } from '~/streaming/render_html_streams';
import { toPolyfillReadable } from '~/streaming/polyfills';

initCommitBoxInfo();
initCommitActions();

const streamContainer = document.getElementById('js-stream-container');
if (streamContainer) {
  const request = fetch(streamContainer.dataset.diffsStreamUrl);
  renderHtmlStreams(
    [request.then((response) => toPolyfillReadable(response.body))],
    streamContainer,
  );
}
