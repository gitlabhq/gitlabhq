<script>
import { uniqueId } from 'lodash-es';
import { __ } from '~/locale';
import TestCaseDetails from '~/ci/pipeline_details/test_reports/test_case_details.vue';
import ReportSection from '~/merge_requests/reports/components/report_section.vue';
import { i18n } from '~/vue_merge_request_widget/widgets/test_report/constants';
import {
  failedTestFiles,
  formatFilePath,
  testSummary,
  testSummarySections,
} from '~/vue_merge_request_widget/widgets/test_report/utils';

export default {
  name: 'TestSummaryContent',
  components: {
    ReportSection,
    TestCaseDetails,
  },
  inject: [
    'isTestSummaryLoading',
    'statusMessage',
    'errorMessage',
    'statusIconName',
    'testReport',
    'fullReportPath',
    'headBlobPath',
  ],
  i18n,
  data() {
    return {
      modalData: null,
    };
  },
  computed: {
    summary() {
      const message = this.statusMessage || this.errorMessage;

      return message ? { title: message } : testSummary(this.testReport);
    },
    suites() {
      return this.testReport.suites || [];
    },
    sections() {
      return testSummarySections(this.suites, (test) => {
        this.modalData = {
          testCase: {
            filePath: test.file && `${this.headBlobPath}/${formatFilePath(test.file)}`,
            ...test,
          },
        };
      });
    },
    actionButtons() {
      const buttons = [];
      const failedTests = failedTestFiles(this.suites);

      if (failedTests) {
        buttons.push({
          dataClipboardText: failedTests,
          id: uniqueId('copy-to-clipboard'),
          icon: 'copy-to-clipboard',
          text: i18n.copyFailedSpecs,
          tooltipText: i18n.copyFailedSpecsTooltip,
          tooltipOnClick: __('Copied'),
        });
      }

      if (this.fullReportPath) {
        buttons.push({
          text: i18n.fullReport,
          href: this.fullReportPath,
          target: '_blank',
        });
      }

      return buttons;
    },
  },
};
</script>

<template>
  <div>
    <report-section
      :is-loading="isTestSummaryLoading"
      :loading-text="$options.i18n.loading"
      :summary="summary"
      :status-icon-name="statusIconName"
      :action-buttons="actionButtons"
      :sections="sections"
    />
    <test-case-details
      modal-id="modalTestSummaryReport"
      :visible="modalData !== null"
      v-bind="modalData"
      @hidden="modalData = null"
    />
  </div>
</template>
