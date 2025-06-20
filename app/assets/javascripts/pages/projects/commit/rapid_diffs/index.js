import initCommitActions from '~/projects/commit';
import { initCommitBoxInfo } from '~/projects/commit_box/info';
import { createRapidDiffsApp } from '~/rapid_diffs/app';

initCommitBoxInfo();
initCommitActions();

const app = createRapidDiffsApp();
app.init();
