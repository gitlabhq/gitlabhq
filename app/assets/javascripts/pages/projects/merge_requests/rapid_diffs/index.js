import { initMrPage } from '~/pages/projects/merge_requests/page';
import { DiffFile } from '~/rapid_diffs/diff_file';
import { DiffFileMounted } from '~/rapid_diffs/diff_file_mounted';

initMrPage();
customElements.define('diff-file', DiffFile);
customElements.define('diff-file-mounted', DiffFileMounted);
