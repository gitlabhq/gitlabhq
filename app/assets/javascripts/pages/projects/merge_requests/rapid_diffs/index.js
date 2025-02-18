import { initMrPage } from '~/pages/projects/merge_requests/page';
import { createRapidDiffsApp } from '~/rapid_diffs/app';

initMrPage();

const app = createRapidDiffsApp();
app.streamRemainingDiffs();
app.init();
