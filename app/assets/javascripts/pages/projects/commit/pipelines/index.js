import { fetchCommitMergeRequests } from '~/commit_merge_requests';
import initCherryPickCommitModal from '~/projects/commit/init_cherry_pick_commit_modal';
import initCommitOptionsDropdown from '~/projects/commit/init_commit_options_dropdown';
import initRevertCommitModal from '~/projects/commit/init_revert_commit_modal';
import initCommitPipelineSummary from '~/projects/commit_box/info/init_commit_pipeline_summary';
import initCommitReferences from '~/projects/commit_box/info/init_commit_references';
import { initCommitPipelines } from '~/commit/pipelines/pipelines_bundle';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

fetchCommitMergeRequests();
initCommitPipelineSummary();
initCommitReferences();

initRevertCommitModal();
initCherryPickCommitModal();
initCommitOptionsDropdown();

if (gon.features?.vue3MigratePipelines) {
  (async () => {
    try {
      // eslint-disable-next-line no-shadow -- Override with Vue 3 app
      const { initCommitPipelines } = await import('~/commit/pipelines/pipelines_bundle?vue3');
      initCommitPipelines();
      return;
    } catch (e) {
      Sentry.captureException(e);
    }

    initCommitPipelines();
  })();
} else {
  initCommitPipelines();
}
