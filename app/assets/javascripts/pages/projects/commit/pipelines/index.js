import initCommitActions from '~/projects/commit';
import { initCommitBoxInfo } from '~/projects/commit_box/info';
import { initCommitPipelines } from '~/commit/pipelines/pipelines_bundle';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

initCommitBoxInfo();
initCommitActions();

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
