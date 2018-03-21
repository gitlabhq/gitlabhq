import Vue from 'vue';
import Flash from '~/flash';
import Translate from '~/vue_shared/translate';
import { __ } from '~/locale';
import PipelinesMediator from './pipeline_details_mediator';
import pipelineGraph from './components/graph/graph_component.vue';
import pipelineHeader from './components/header_component.vue';
import eventHub from './event_hub';

import SecurityReportApp from 'ee/pipelines/components/security_reports/security_report_app.vue'; // eslint-disable-line import/first
import SastSummaryWidget from 'ee/pipelines/components/security_reports/sast_report_summary_widget.vue'; // eslint-disable-line import/first

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

    if (endpoint) {
      mediator.fetchSastReport(endpoint, blobPath)
      .then(() => {
        // update the badge
        if (mediator.store.state.securityReports.sast.newIssues.length) {
          updateBadgeCount(mediator.store.state.securityReports.sast.newIssues.length);
        }
      })
      .catch(() => {
        Flash(__('Something went wrong while fetching SAST.'));
      });
    }

    if (dependencyScanningEndpoint) {
      mediator.fetchDependencyScanningReport(dependencyScanningEndpoint)
      .then(() => {
        // update the badge
        if (mediator.store.state.securityReports.dependencyScanning.newIssues.length) {
          updateBadgeCount(
            mediator.store.state.securityReports.dependencyScanning.newIssues.length,
          );
        }
      })
      .catch(() => {
        Flash(__('Something went wrong while fetching Dependency Scanning.'));
      });
    }

    // Widget summary
    // eslint-disable-next-line no-new
    new Vue({
      el: sastSummary,
      components: {
        SastSummaryWidget,
      },
      data() {
        return {
          mediator,
        };
      },
      render(createElement) {
        return createElement('sast-summary-widget', {
          props: {
            unresolvedIssues: this.mediator.store.state.securityReports.sast.newIssues.length +
              this.mediator.store.state.securityReports.dependencyScanning.newIssues.length,
          },
        });
      },
    });

    // Tab content
    // eslint-disable-next-line no-new
    new Vue({
      el: securityTab,
      components: {
        SecurityReportApp,
      },
      data() {
        return {
          mediator,
        };
      },
      render(createElement) {
        return createElement('security-report-app', {
          props: {
            securityReports: this.mediator.store.state.securityReports,
            hasDependencyScanning: dependencyScanningEndpoint !== undefined,
            hasSast: endpoint !== undefined,
          },
        });
      },
    });
  }
};
