import { initAdminRunnerShow } from '~/ci/runner/admin_runner_show';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

async function init() {
  if (gon.features?.vue3MigrateAdminRunners) {
    try {
      // eslint-disable-next-line no-shadow -- Override with Vue 3 app
      const { initAdminRunnerShow } = await import('~/ci/runner/admin_runner_show?vue3');
      initAdminRunnerShow();
      return;
    } catch (e) {
      Sentry.captureException(e);
    }
  }
  initAdminRunnerShow();
}

init();
