import { initMrPage } from '~/pages/projects/merge_requests/page';
import { createMergeRequestRapidDiffsApp } from 'ee_else_ce/rapid_diffs/merge_request_app';

initMrPage(createMergeRequestRapidDiffsApp);
