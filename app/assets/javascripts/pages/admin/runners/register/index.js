import { initAdminRegisterRunner } from '~/ci/runner/admin_register_runner';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

async function init() {
  if (gon.features?.vue3MigrateAdminRunners) {
    try {
      // eslint-disable-next-line no-shadow -- Override with Vue 3 app
      const { initAdminRegisterRunner } = await import('~/ci/runner/admin_register_runner?vue3');
      initAdminRegisterRunner();
      return;
    } catch (e) {
      Sentry.captureException(e);
    }
  }
  initAdminRegisterRunner();
}

init();
