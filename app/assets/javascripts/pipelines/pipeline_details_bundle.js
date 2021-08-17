import Vue from 'vue';
import createFlash from '~/flash';
import { parseBoolean } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import Translate from '~/vue_shared/translate';
import TestReports from './components/test_reports/test_reports.vue';
import createDagApp from './pipeline_details_dag';
import { createPipelinesDetailApp } from './pipeline_details_graph';
import { createPipelineHeaderApp } from './pipeline_details_header';
import { apolloProvider } from './pipeline_shared_client';
import createTestReportsStore from './stores/test_reports';

Vue.use(Translate);

const SELECTORS = {
  PIPELINE_DETAILS: '.js-pipeline-details-vue',
  PIPELINE_GRAPH: '#js-pipeline-graph-vue',
  PIPELINE_HEADER: '#js-pipeline-header-vue',
  PIPELINE_TESTS: '#js-pipeline-tests-detail',
};

const createTestDetails = () => {
  const el = document.querySelector(SELECTORS.PIPELINE_TESTS);
  const { blobPath, emptyStateImagePath, hasTestReport, summaryEndpoint, suiteEndpoint } =
    el?.dataset || {};
  const testReportsStore = createTestReportsStore({
    blobPath,
    summaryEndpoint,
    suiteEndpoint,
  });

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      TestReports,
    },
    provide: {
      emptyStateImagePath,
      hasTestReport: parseBoolean(hasTestReport),
    },
    store: testReportsStore,
    render(createElement) {
      return createElement('test-reports');
    },
  });
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

  createDagApp(apolloProvider);
  createTestDetails();
}
