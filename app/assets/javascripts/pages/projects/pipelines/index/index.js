import { initPipelinesIndex } from '~/ci/pipeline_details/pipelines_index';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

async function init() {
  if (gon.features?.vue3MigratePipelines) {
    try {
      // eslint-disable-next-line no-shadow -- Override with Vue 3 app
      const { initPipelinesIndex } = await import('~/ci/pipeline_details/pipelines_index?vue3');
      initPipelinesIndex();
      return;
    } catch (e) {
      Sentry.captureException(e);
    }
  }
  initPipelinesIndex();
}

init();
