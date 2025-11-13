import ZenMode from '~/zen_mode';
import initCommitActions from '~/projects/commit';
import { initCommitBoxInfo } from '~/projects/commit_box/info';
import { createCommitRapidDiffsApp } from '~/rapid_diffs/commit_app';

// eslint-disable-next-line no-new
new ZenMode();
initCommitBoxInfo();
initCommitActions();

const app = createCommitRapidDiffsApp();
app.init();
app.initDiscussions();
