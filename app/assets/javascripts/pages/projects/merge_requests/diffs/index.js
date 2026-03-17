import initDiffsApp from '~/diffs';
import { initMrPage } from '~/pages/projects/merge_requests/page';
import { lazyCreateRapidDiffsApp } from '~/pages/projects/merge_requests/lazy_create_rapid_diffs_app';

initMrPage(lazyCreateRapidDiffsApp);
initDiffsApp();
