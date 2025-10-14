import {
  initPipelinesIndex,
  initPipelinesIndexGraphql,
} from '~/ci/pipeline_details/pipelines_index';

const shouldUseGraphql = gon?.features?.pipelinesPageGraphql;

if (shouldUseGraphql) {
  initPipelinesIndexGraphql();
} else {
  initPipelinesIndex();
}
