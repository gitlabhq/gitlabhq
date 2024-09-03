import { initMrPage } from '~/pages/projects/merge_requests/page';
import { DiffFile } from '~/rapid_diffs/diff_file';
import { DiffFileMounted } from '~/rapid_diffs/diff_file_mounted';
import { renderHtmlStreams } from '~/streaming/render_html_streams';
import { toPolyfillReadable } from '~/streaming/polyfills';

initMrPage();

const streamContainer = document.getElementById('js-stream-container');
if (streamContainer) {
  const request = fetch(streamContainer.dataset.diffsStreamUrl);
  renderHtmlStreams(
    [request.then((response) => toPolyfillReadable(response.body))],
    streamContainer,
  );
}

customElements.define('diff-file', DiffFile);
customElements.define('diff-file-mounted', DiffFileMounted);
