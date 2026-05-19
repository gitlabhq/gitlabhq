import { initAdminRunners } from '~/ci/runner/admin_runners';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

async function init() {
  if (gon.features?.vue3MigrateAdminRunners) {
    try {
      // eslint-disable-next-line no-shadow -- Override with Vue 3 app
      const { initAdminRunners } = await import('~/ci/runner/admin_runners?vue3');
      initAdminRunners();
      return;
    } catch (e) {
      Sentry.captureException(e);
    }
  }
  initAdminRunners();
}

init();
