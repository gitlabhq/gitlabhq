import createFlash from '~/flash';
import { __ } from '~/locale';
import createDagApp from './pipeline_details_dag';
import { createPipelinesDetailApp } from './pipeline_details_graph';
import { createPipelineHeaderApp } from './pipeline_details_header';
import { apolloProvider } from './pipeline_shared_client';
import { createTestDetails } from './pipeline_test_details';

const SELECTORS = {
  PIPELINE_DETAILS: '.js-pipeline-details-vue',
  PIPELINE_GRAPH: '#js-pipeline-graph-vue',
  PIPELINE_HEADER: '#js-pipeline-header-vue',
  PIPELINE_TESTS: '#js-pipeline-tests-detail',
};

export default async function initPipelineDetailsBundle() {
  const { dataset } = document.querySelector(SELECTORS.PIPELINE_DETAILS);

  try {
    createPipelineHeaderApp(SELECTORS.PIPELINE_HEADER, apolloProvider, dataset.graphqlResourceEtag);
  } catch {
    createFlash({
      message: __('An error occurred while loading a section of this page.'),
    });
  }

  try {
    createPipelinesDetailApp(SELECTORS.PIPELINE_GRAPH, apolloProvider, dataset);
  } catch {
    createFlash({
      message: __('An error occurred while loading the pipeline.'),
    });
  }

  try {
    createPipelineHeaderApp(SELECTORS.PIPELINE_HEADER, apolloProvider, dataset.graphqlResourceEtag);
  } catch {
    createFlash({
      message: __('An error occurred while loading a section of this page.'),
    });
  }

  try {
    createDagApp(apolloProvider);
  } catch {
    createFlash({
      message: __('An error occurred while loading the Needs tab.'),
    });
  }

  try {
    createTestDetails(SELECTORS.PIPELINE_TESTS);
  } catch {
    createFlash({
      message: __('An error occurred while loading the Test Reports tab.'),
    });
  }
}
