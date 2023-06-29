import mountNotesApp from 'ee_else_ce/mr_notes/mount_app';
import { initReportAbuse } from '~/projects/report_abuse';
import { initMrMoreDropdown } from '~/mr_more_dropdown';
import { initMrPage } from 'ee_else_ce/pages/projects/merge_requests/page';

initMrPage();
mountNotesApp();
initReportAbuse();
initMrMoreDropdown();
