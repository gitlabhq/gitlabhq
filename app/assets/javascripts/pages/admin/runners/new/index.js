import { initAdminNewRunner } from '~/ci/runner/admin_new_runner';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

async function init() {
  if (gon.features?.vue3MigrateAdminRunners) {
    try {
      // eslint-disable-next-line no-shadow -- Override with Vue 3 app
      const { initAdminNewRunner } = await import('~/ci/runner/admin_new_runner?vue3');
      initAdminNewRunner();
      return;
    } catch (e) {
      Sentry.captureException(e);
    }
  }
  initAdminNewRunner();
}

init();
