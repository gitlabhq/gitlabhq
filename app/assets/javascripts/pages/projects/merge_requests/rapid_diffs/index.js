import { initMrPage } from '~/pages/projects/merge_requests/page';
import { pinia } from '~/rapid_diffs/app/pinia';
import { initViewSettings } from '~/rapid_diffs/app/view_settings';
import { DiffFile } from '~/rapid_diffs/diff_file';
import { DiffFileMounted } from '~/rapid_diffs/diff_file_mounted';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';

initMrPage();

const streamContainer = document.getElementById('js-stream-container');
if (streamContainer) {
  useDiffsList(pinia).streamRemainingDiffs(streamContainer.dataset.diffsStreamUrl);
}

customElements.define('diff-file', DiffFile);
customElements.define('diff-file-mounted', DiffFileMounted);

const appElement = document.querySelector('[data-rapid-diffs]');
if (appElement) {
  initViewSettings({ pinia, streamUrl: appElement.dataset.reloadStreamUrl });
}
