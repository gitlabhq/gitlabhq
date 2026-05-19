import { initJobsPage } from '~/ci/jobs_page';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

async function init() {
  if (gon.features?.vue3MigrateJobs) {
    try {
      // eslint-disable-next-line no-shadow -- Override with Vue 3 app
      const { initJobsPage } = await import('~/ci/jobs_page?vue3');
      initJobsPage();
      return;
    } catch (e) {
      Sentry.captureException(e);
    }
  }
  initJobsPage();
}

init();
