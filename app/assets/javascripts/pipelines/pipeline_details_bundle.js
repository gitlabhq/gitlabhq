import Vue from 'vue';
import { deprecatedCreateFlash as Flash } from '~/flash';
import Translate from '~/vue_shared/translate';
import { __ } from '~/locale';
import { setUrlFragment, redirectTo } from '~/lib/utils/url_utility';
import PipelineGraphLegacy from './components/graph/graph_component_legacy.vue';
import createDagApp from './pipeline_details_dag';
import GraphBundleMixin from './mixins/graph_pipeline_bundle_mixin';
import legacyPipelineHeader from './components/legacy_header_component.vue';
import eventHub from './event_hub';
import TestReports from './components/test_reports/test_reports.vue';
import createTestReportsStore from './stores/test_reports';

Vue.use(Translate);

const SELECTORS = {
  PIPELINE_DETAILS: '.js-pipeline-details-vue',
  PIPELINE_GRAPH: '#js-pipeline-graph-vue',
  PIPELINE_HEADER: '#js-pipeline-header-vue',
  PIPELINE_TESTS: '#js-pipeline-tests-detail',
};

const createLegacyPipelinesDetailApp = mediator => {
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
          onClickUpstreamPipeline: pipeline => this.clickUpstreamPipeline(pipeline),
          onClickDownstreamPipeline: pipeline => this.clickDownstreamPipeline(pipeline),
        },
      });
    },
  });
};

const createLegacyPipelineHeaderApp = mediator => {
  if (!document.querySelector(SELECTORS.PIPELINE_HEADER)) {
    return;
  }
  // eslint-disable-next-line no-new
  new Vue({
    el: SELECTORS.PIPELINE_HEADER,
    components: {
      legacyPipelineHeader,
    },
    data() {
      return {
        mediator,
      };
    },
    created() {
      eventHub.$on('headerPostAction', this.postAction);
      eventHub.$on('headerDeleteAction', this.deleteAction);
    },
    beforeDestroy() {
      eventHub.$off('headerPostAction', this.postAction);
      eventHub.$off('headerDeleteAction', this.deleteAction);
    },
    methods: {
      postAction(path) {
        this.mediator.service
          .postAction(path)
          .then(() => this.mediator.refreshPipeline())
          .catch(() => Flash(__('An error occurred while making the request.')));
      },
      deleteAction(path) {
        this.mediator.stopPipelinePoll();
        this.mediator.service
          .deleteAction(path)
          .then(({ request }) => redirectTo(setUrlFragment(request.responseURL, 'delete_success')))
          .catch(() => Flash(__('An error occurred while deleting the pipeline.')));
      },
    },
    render(createElement) {
      return createElement('legacy-pipeline-header', {
        props: {
          isLoading: this.mediator.state.isLoading,
          pipeline: this.mediator.store.state.pipeline,
        },
      });
    },
  });
};

const createTestDetails = () => {
  const el = document.querySelector(SELECTORS.PIPELINE_TESTS);
  const { summaryEndpoint, suiteEndpoint } = el?.dataset || {};
  const testReportsStore = createTestReportsStore({
    summaryEndpoint,
    suiteEndpoint,
  });

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      TestReports,
    },
    store: testReportsStore,
    render(createElement) {
      return createElement('test-reports');
    },
  });
};

export default async function() {
  createTestDetails();
  createDagApp();

  const { dataset } = document.querySelector(SELECTORS.PIPELINE_DETAILS);
  let mediator;

  if (!gon.features.graphqlPipelineHeader || !gon.features.graphqlPipelineDetails) {
    try {
      const { default: PipelinesMediator } = await import(
        /* webpackChunkName: 'PipelinesMediator' */ './pipeline_details_mediator'
      );
      mediator = new PipelinesMediator({ endpoint: dataset.endpoint });
      mediator.fetchPipeline();
    } catch {
      Flash(__('An error occurred while loading the pipeline.'));
    }
  }

  if (gon.features.graphqlPipelineDetails) {
    try {
      const { createPipelinesDetailApp } = await import(
        /* webpackChunkName: 'createPipelinesDetailApp' */ './pipeline_details_graph'
      );

      const { pipelineProjectPath, pipelineIid } = dataset;
      createPipelinesDetailApp(SELECTORS.PIPELINE_DETAILS, pipelineProjectPath, pipelineIid);
    } catch {
      Flash(__('An error occurred while loading the pipeline.'));
    }
  } else {
    createLegacyPipelinesDetailApp(mediator);
  }

  if (gon.features.graphqlPipelineHeader) {
    try {
      const { createPipelineHeaderApp } = await import(
        /* webpackChunkName: 'createPipelineHeaderApp' */ './pipeline_details_header'
      );
      createPipelineHeaderApp(SELECTORS.PIPELINE_HEADER);
    } catch {
      Flash(__('An error occurred while loading a section of this page.'));
    }
  } else {
    createLegacyPipelineHeaderApp(mediator);
  }
}
