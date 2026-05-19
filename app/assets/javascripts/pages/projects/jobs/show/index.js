import { initJobDetails } from '~/ci/job_details';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

async function init() {
  if (gon.features?.vue3MigrateJobs) {
    try {
      // eslint-disable-next-line no-shadow -- Override with Vue 3 app
      const { initJobDetails } = await import('~/ci/job_details?vue3');
      initJobDetails();
      return;
    } catch (e) {
      Sentry.captureException(e);
    }
  }
  initJobDetails();
}

init();
