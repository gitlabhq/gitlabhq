import mountNotesApp from '~/mr_notes/mount_app';
import { initMrPage } from '~/pages/projects/merge_requests/page';
import { lazyCreateRapidDiffsApp } from '~/pages/projects/merge_requests/lazy_create_rapid_diffs_app';
import { getAiOverviewEl } from '~/merge_requests/utils/ai_overview';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';

initMrPage(lazyCreateRapidDiffsApp);

// The AI overview replaces the whole Overview tab, so only one of the two apps is mounted.
const aiOverviewEl = getAiOverviewEl();

if (aiOverviewEl) {
  import('ee_else_ce/merge_requests/ai_overview')
    .then(({ default: initAiOverviewApp }) => initAiOverviewApp(aiOverviewEl))
    .catch(() => {
      createAlert({ message: s__('MergeRequest|Failed to load the page') });
    });
} else {
  mountNotesApp();
}
