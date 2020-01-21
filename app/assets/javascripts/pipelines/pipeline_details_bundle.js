import Vue from 'vue';
import Flash from '~/flash';
import Translate from '~/vue_shared/translate';
import { __ } from '~/locale';
import { setUrlFragment, redirectTo } from '~/lib/utils/url_utility';
import pipelineGraph from './components/graph/graph_component.vue';
import GraphBundleMixin from './mixins/graph_pipeline_bundle_mixin';
import PipelinesMediator from './pipeline_details_mediator';
import pipelineHeader from './components/header_component.vue';
import eventHub from './event_hub';
import TestReports from './components/test_reports/test_reports.vue';
import testReportsStore from './stores/test_reports';

Vue.use(Translate);

export default () => {
  const { dataset } = document.querySelector('.js-pipeline-details-vue');

  const mediator = new PipelinesMediator({ endpoint: dataset.endpoint });

  mediator.fetchPipeline();

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
          onClickTriggeredBy: (parentPipeline, pipeline) =>
            this.clickTriggeredByPipeline(parentPipeline, pipeline),
          onClickTriggered: (parentPipeline, pipeline) =>
            this.clickTriggeredPipeline(parentPipeline, pipeline),
        },
      });
    },
  });

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
      postAction(action) {
        this.mediator.service
          .postAction(action.path)
          .then(() => this.mediator.refreshPipeline())
          .catch(() => Flash(__('An error occurred while making the request.')));
      },
      deleteAction(action) {
        this.mediator.stopPipelinePoll();
        this.mediator.service
          .deleteAction(action.path)
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

  const testReportsEnabled =
    window.gon && window.gon.features && window.gon.features.junitPipelineView;

  if (testReportsEnabled) {
    testReportsStore.dispatch('setEndpoint', dataset.testReportEndpoint);
    testReportsStore.dispatch('fetchReports');

    // eslint-disable-next-line no-new
    new Vue({
      el: '#js-pipeline-tests-detail',
      components: {
        TestReports,
      },
      render(createElement) {
        return createElement('test-reports');
      },
    });
  }
};
