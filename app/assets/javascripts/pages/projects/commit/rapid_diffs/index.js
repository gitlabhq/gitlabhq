import initCommitActions from '~/projects/commit';
import { initCommitBoxInfo } from '~/projects/commit_box/info';
import { createCommitRapidDiffsApp } from '~/rapid_diffs/commit_app';

initCommitBoxInfo();
initCommitActions();

const app = createCommitRapidDiffsApp();
app.init();
