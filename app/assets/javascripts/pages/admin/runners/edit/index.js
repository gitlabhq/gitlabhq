import { initRunnerEdit } from '~/ci/runner/runner_edit';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

async function init() {
  if (gon.features?.vue3MigrateAdminRunners) {
    try {
      // eslint-disable-next-line no-shadow -- Override with Vue 3 app
      const { initRunnerEdit } = await import('~/ci/runner/runner_edit?vue3');
      initRunnerEdit('#js-admin-runner-edit');
      return;
    } catch (e) {
      Sentry.captureException(e);
    }
  }
  initRunnerEdit('#js-admin-runner-edit');
}

init();
