import initPipelineDetails from '~/pipelines/pipeline_details_bundle';
import initPipelines from '~/pages/projects/pipelines/init_pipelines';

document.addEventListener('DOMContentLoaded', () => {
  initPipelines();
  initPipelineDetails();
});
