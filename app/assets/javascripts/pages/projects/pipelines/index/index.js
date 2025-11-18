import {
  initPipelinesIndex,
  initPipelinesIndexGraphql,
} from '~/ci/pipeline_details/pipelines_index';

const shouldUseGraphql =
  gon?.features?.pipelinesPageGraphql && gon?.features?.ciPipelineStatusesUpdatedSubscription;

if (shouldUseGraphql) {
  initPipelinesIndexGraphql();
} else {
  initPipelinesIndex();
}
