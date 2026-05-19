import { initAdminJobsApp } from '~/ci/admin/jobs_table/index';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

async function init() {
  if (gon.features?.vue3MigrateJobs) {
    try {
      // eslint-disable-next-line no-shadow -- Override with Vue 3 app
      const { initAdminJobsApp } = await import('~/ci/admin/jobs_table/index?vue3');
      initAdminJobsApp();
      return;
    } catch (e) {
      Sentry.captureException(e);
    }
  }
  initAdminJobsApp();
}

init();
