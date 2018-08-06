import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import SecurityReportApp from 'ee/vue_shared/security_reports/split_security_reports_app.vue';
import SastSummaryWidget from 'ee/pipelines/components/security_reports/report_summary_widget.vue';
import createStore from 'ee/vue_shared/security_reports/store';
import { convertPermissionToBoolean } from '~/lib/utils/common_utils';
import { updateBadgeCount } from './utils';

Vue.use(Translate);

export default () => {
  const securityTab = document.getElementById('js-security-report-app');
  const sastSummary = document.querySelector('.js-sast-summary');

  // They are being rendered under the same condition
  if (securityTab) {
    const datasetOptions = securityTab.dataset;
    const {
      headBlobPath,
      sastHeadPath,
      sastHelpPath,
      dependencyScanningHeadPath,
      dependencyScanningHelpPath,
      vulnerabilityFeedbackPath,
      vulnerabilityFeedbackHelpPath,
      dastHeadPath,
      sastContainerHeadPath,
      dastHelpPath,
      sastContainerHelpPath,
      canCreateIssue,
      canCreateFeedback,
    } = datasetOptions;
    const pipelineId = parseInt(datasetOptions.pipelineId, 10);

    const store = createStore();

    // Widget summary
    if (sastSummary) {
      // eslint-disable-next-line no-new
      new Vue({
        el: sastSummary,
        store,
        components: {
          SastSummaryWidget,
        },
        render(createElement) {
          return createElement('sast-summary-widget');
        },
      });
    }

    // Tab content
    // eslint-disable-next-line no-new
    new Vue({
      el: securityTab,
      store,
      components: {
        SecurityReportApp,
      },
      render(createElement) {
        return createElement('security-report-app', {
          props: {
            headBlobPath,
            sastHeadPath,
            sastHelpPath,
            dependencyScanningHeadPath,
            dependencyScanningHelpPath,
            vulnerabilityFeedbackPath,
            vulnerabilityFeedbackHelpPath,
            pipelineId,
            dastHeadPath,
            sastContainerHeadPath,
            dastHelpPath,
            sastContainerHelpPath,
            canCreateFeedback: convertPermissionToBoolean(canCreateFeedback),
            canCreateIssue: convertPermissionToBoolean(canCreateIssue),
          },
          on: {
            updateBadgeCount: (count) => {
              updateBadgeCount('.js-sast-counter', count);
            },
          },
        });
      },
    });
  }
};
