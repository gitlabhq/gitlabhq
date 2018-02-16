import Vue from 'vue';
import Flash from '~/flash';
import Translate from '~/vue_shared/translate';
import PipelinesMediator from './pipeline_details_mediator';
import pipelineGraph from './components/graph/graph_component.vue';
import pipelineHeader from './components/header_component.vue';
import eventHub from './event_hub';
import SecurityReportApp from './components/security_reports/security_report_app.vue';

Vue.use(Translate);

document.addEventListener('DOMContentLoaded', () => {
  const dataset = document.querySelector('.js-pipeline-details-vue').dataset;

  const mediator = new PipelinesMediator({ endpoint: dataset.endpoint });

  mediator.fetchPipeline();

  // eslint-disable-next-line
  new Vue({
    el: '#js-pipeline-graph-vue',
    components: {
      pipelineGraph,
    },
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
        },
      });
    },
  });

  // eslint-disable-next-line
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
    },
    beforeDestroy() {
      eventHub.$off('headerPostAction', this.postAction);
    },
    methods: {
      postAction(action) {
        this.mediator.service.postAction(action.path)
          .then(() => this.mediator.refreshPipeline())
          .catch(() => Flash('An error occurred while making the request.'));
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

  /**
   * EE only
   */

  const securityTab = document.getElementById('js-security-report-app');

  if (securityTab) {
    // eslint-disable-next-line no-new
    new Vue({
      el: securityTab,
      components: {
        SecurityReportApp,
      },
      data() {
        const datasetOptions = this.$options.el.dataset;
        return {
          endpoint: datasetOptions.endpoint,
          blobPath: datasetOptions.blobPath,
          mediator,
        };
      },
      created() {
        this.mediator.fetchSastReport(this.endpoint, this.blobPath);
      },
      render(createElement) {
        return createElement('security-report-app', {
          props: {
            securityReports: this.mediator.store.state.securityReports,
          },
        });
      },
    });
  }
});
