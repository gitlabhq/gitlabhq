import Vue from 'vue';
import createFlash from '~/flash';
import { parseBoolean } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import Translate from '~/vue_shared/translate';
import PipelineGraphLegacy from './components/graph/graph_component_legacy.vue';
import TestReports from './components/test_reports/test_reports.vue';
import GraphBundleMixin from './mixins/graph_pipeline_bundle_mixin';
import createDagApp from './pipeline_details_dag';
import { createPipelinesDetailApp } from './pipeline_details_graph';
import { createPipelineHeaderApp } from './pipeline_details_header';
import { apolloProvider } from './pipeline_shared_client';
import createTestReportsStore from './stores/test_reports';
import { reportToSentry } from './utils';

Vue.use(Translate);

const SELECTORS = {
  PIPELINE_DETAILS: '.js-pipeline-details-vue',
  PIPELINE_GRAPH: '#js-pipeline-graph-vue',
  PIPELINE_HEADER: '#js-pipeline-header-vue',
  PIPELINE_TESTS: '#js-pipeline-tests-detail',
};

const createLegacyPipelinesDetailApp = (mediator) => {
  if (!document.querySelector(SELECTORS.PIPELINE_GRAPH)) {
    return;
  }
  // eslint-disable-next-line no-new
  new Vue({
    el: SELECTORS.PIPELINE_GRAPH,
    components: {
      PipelineGraphLegacy,
    },
    mixins: [GraphBundleMixin],
    data() {
      return {
        mediator,
      };
    },
    errorCaptured(err, _vm, info) {
      reportToSentry('pipeline_details_bundle_legacy_details', `error: ${err}, info: ${info}`);
    },
    render(createElement) {
      return createElement('pipeline-graph-legacy', {
        props: {
          isLoading: this.mediator.state.isLoading,
          pipeline: this.mediator.store.state.pipeline,
          mediator: this.mediator,
        },
        on: {
          refreshPipelineGraph: this.requestRefreshPipelineGraph,
          onResetDownstream: (parentPipeline, pipeline) =>
            this.resetDownstreamPipelines(parentPipeline, pipeline),
          onClickUpstreamPipeline: (pipeline) => this.clickUpstreamPipeline(pipeline),
          onClickDownstreamPipeline: (pipeline) => this.clickDownstreamPipeline(pipeline),
        },
      });
    },
  });
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
  const canShowNewPipelineDetails =
    gon.features.graphqlPipelineDetails || gon.features.graphqlPipelineDetailsUsers;

  const { dataset } = document.querySelector(SELECTORS.PIPELINE_DETAILS);

  try {
    createPipelineHeaderApp(SELECTORS.PIPELINE_HEADER, apolloProvider, dataset.graphqlResourceEtag);
  } catch {
    createFlash({
      message: __('An error occurred while loading a section of this page.'),
    });
  }

  if (canShowNewPipelineDetails) {
    try {
      createPipelinesDetailApp(SELECTORS.PIPELINE_GRAPH, apolloProvider, dataset);
    } catch {
      createFlash({
        message: __('An error occurred while loading the pipeline.'),
      });
    }
  } else {
    const { default: PipelinesMediator } = await import(
      /* webpackChunkName: 'PipelinesMediator' */ './pipeline_details_mediator'
    );
    const mediator = new PipelinesMediator({ endpoint: dataset.endpoint });
    mediator.fetchPipeline();

    createLegacyPipelinesDetailApp(mediator);
  }

  createDagApp(apolloProvider);
  createTestDetails();
}
