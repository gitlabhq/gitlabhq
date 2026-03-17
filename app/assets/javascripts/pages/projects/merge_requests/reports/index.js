import { initMrPage } from '~/pages/projects/merge_requests/page';
import { lazyCreateRapidDiffsApp } from '~/pages/projects/merge_requests/lazy_create_rapid_diffs_app';
import initReportsApp from '~/merge_requests/reports';

initMrPage(lazyCreateRapidDiffsApp);
initReportsApp();
