import Vue from 'vue';
import Flash from '~/flash';
import Translate from '~/vue_shared/translate';
import { __ } from '~/locale';
import { setUrlFragment, redirectTo } from '~/lib/utils/url_utility';
import pipelineGraph from './components/graph/graph_component.vue';
import Dag from './components/dag/dag.vue';
import GraphBundleMixin from './mixins/graph_pipeline_bundle_mixin';
import PipelinesMediator from './pipeline_details_mediator';
import pipelineHeader from './components/header_component.vue';
import eventHub from './event_hub';
import TestReports from './components/test_reports/test_reports.vue';
import createTestReportsStore from './stores/test_reports';

Vue.use(Translate);

const createPipelinesDetailApp = mediator => {
  // eslint-disable-next-line no-new
  new Vue({
    el: '#js-pipeline-graph-vue',
    components: {
      pipelineGraph,
    },
    mixins: [GraphBundleMixin],
    data() {
      return {
        mediator,
      };
    },
    render(createElement) {
      return createElement('pipeline-graph', {
        props: {
          isLoading: this.mediator.state.isLoading,
          pipeline: this.mediator.store.state.pipeline,
          mediator: this.mediator,
        },
        on: {
          refreshPipelineGraph: this.requestRefreshPipelineGraph,
          onResetTriggered: (parentPipeline, pipeline) =>
            this.resetTriggeredPipelines(parentPipeline, pipeline),
          onClickTriggeredBy: pipeline => this.clickTriggeredByPipeline(pipeline),
          onClickTriggered: pipeline => this.clickTriggeredPipeline(pipeline),
        },
      });
    },
  });
};

const createPipelineHeaderApp = mediator => {
  // eslint-disable-next-line no-new
  new Vue({
    el: '#js-pipeline-header-vue',
    components: {
      pipelineHeader,
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
      return createElement('pipeline-header', {
        props: {
          isLoading: this.mediator.state.isLoading,
          pipeline: this.mediator.store.state.pipeline,
        },
      });
    },
  });
};

const createPipelinesTabs = testReportsStore => {
  const tabsElement = document.querySelector('.pipelines-tabs');

  if (tabsElement) {
    const fetchReportsAction = 'fetchFullReport';
    const isTestTabActive = Boolean(
      document.querySelector('.pipelines-tabs > li > a.test-tab.active'),
    );

    if (isTestTabActive) {
      testReportsStore.dispatch(fetchReportsAction);
    } else {
      const tabClickHandler = e => {
        if (e.target.className === 'test-tab') {
          testReportsStore.dispatch(fetchReportsAction);
          tabsElement.removeEventListener('click', tabClickHandler);
        }
      };

      tabsElement.addEventListener('click', tabClickHandler);
    }
  }
};

const createTestDetails = () => {
  if (!window.gon?.features?.junitPipelineView) {
    return;
  }

  const el = document.querySelector('#js-pipeline-tests-detail');
  const { fullReportEndpoint, countEndpoint } = el?.dataset || {};

  const testReportsStore = createTestReportsStore({
    fullReportEndpoint,
    summaryEndpoint: countEndpoint,
  });
  createPipelinesTabs(testReportsStore);

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

const createDagApp = () => {
  if (!window.gon?.features?.dagPipelineTab) {
    return;
  }

  const el = document.querySelector('#js-pipeline-dag-vue');
  const { pipelineDataPath, emptySvgPath, dagDocPath } = el?.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      Dag,
    },
    render(createElement) {
      return createElement('dag', {
        props: {
          graphUrl: pipelineDataPath,
          emptySvgPath,
          dagDocPath,
        },
      });
    },
  });
};

export default () => {
  const { dataset } = document.querySelector('.js-pipeline-details-vue');
  const mediator = new PipelinesMediator({ endpoint: dataset.endpoint });
  mediator.fetchPipeline();

  createPipelinesDetailApp(mediator);
  createPipelineHeaderApp(mediator);
  createTestDetails();
  createDagApp();
};
