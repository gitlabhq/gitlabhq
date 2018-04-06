import Vue from 'vue';
import Flash from '~/flash';
import Translate from '~/vue_shared/translate';
import { __ } from '~/locale';
import PipelinesMediator from './pipeline_details_mediator';
import pipelineGraph from './components/graph/graph_component.vue';
import pipelineHeader from './components/header_component.vue';
import eventHub from './event_hub';

import SecurityReportApp from 'ee/vue_shared/security_reports/split_security_reports_app.vue'; // eslint-disable-line import/first
import SastSummaryWidget from 'ee/pipelines/components/security_reports/report_summary_widget.vue'; // eslint-disable-line import/first
import store from 'ee/vue_shared/security_reports/store'; // eslint-disable-line import/first

Vue.use(Translate);

export default () => {
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
          .catch(() => Flash(__('An error occurred while making the request.')));
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
  const sastSummary = document.querySelector('.js-sast-summary');

  const updateBadgeCount = (count) => {
    const badge = document.querySelector('.js-sast-counter');
    if (badge.textContent !== '') {
      badge.textContent = parseInt(badge.textContent, 10) + count;
    } else {
      badge.textContent = count;
    }

    badge.classList.remove('hidden');
  };

  // They are being rendered under the same condition
  if (securityTab && sastSummary) {
    const datasetOptions = securityTab.dataset;
    const endpoint = datasetOptions.endpoint;
    const blobPath = datasetOptions.blobPath;
    const dependencyScanningEndpoint = datasetOptions.dependencyScanningEndpoint;

    // Widget summary
    // eslint-disable-next-line no-new
    new Vue({
      el: sastSummary,
      store,
      components: {
        SastSummaryWidget,
      },
      methods: {
        updateBadge(count) {
          updateBadgeCount(count);
        },
      },
      render(createElement) {
        return createElement('sast-summary-widget', {
          on: {
            updateBadgeCount: this.updateBadge,
          },
        });
      },
    });

    // Tab content
    // eslint-disable-next-line no-new
    new Vue({
      el: securityTab,
      store,
      components: {
        SecurityReportApp,
      },
      methods: {
        updateBadge(count) {
          updateBadgeCount(count);
        },
      },
      render(createElement) {
        return createElement('security-report-app', {
          props: {
            headBlobPath: blobPath,
            sastHeadPath: endpoint,
            dependencyScanningHeadPath: dependencyScanningEndpoint,
          },
          on: {
            updateBadgeCount: this.updateBadge,
          },
        });
      },
    });
  }
};
