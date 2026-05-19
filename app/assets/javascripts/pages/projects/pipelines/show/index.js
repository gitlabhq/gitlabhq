import { initPipelineDetails } from '~/ci/pipeline_details/pipeline_details_bundle';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

async function init() {
  if (gon.features?.vue3MigratePipelines) {
    try {
      // eslint-disable-next-line no-shadow -- Override with Vue 3 app
      const { initPipelineDetails } = await import(
        '~/ci/pipeline_details/pipeline_details_bundle?vue3'
      );
      initPipelineDetails();
      return;
    } catch (e) {
      Sentry.captureException(e);
    }
  }
  initPipelineDetails();
}

init();
