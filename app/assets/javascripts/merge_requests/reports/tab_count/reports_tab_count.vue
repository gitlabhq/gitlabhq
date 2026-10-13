<script>
import { observable } from '~/lib/utils/observable';
import { SECURITY_SCAN_TO_REPORT_TYPE } from '~/vue_merge_request_widget/constants';
import mergeRequestData, { PIPELINE_STATE } from '~/merge_requests/reports/merge_request_data';

const SCAN_TYPES = Object.keys(SECURITY_SCAN_TO_REPORT_TYPE).filter(
  (type) => type !== 'clusterImageScanning',
);

const tabData = observable('mr_page_tab_data', { tabs: [] });

export default {
  name: 'ReportsTabCount',
  mixins: [mergeRequestData],
  computed: {
    text() {
      // Pipeline reports are unknown until the pipeline finishes, so status checks
      // are the only report that can be counted before then.
      if (this.pipelineState !== PIPELINE_STATE.complete) {
        return this.hasStatusChecksReports ? '1' : '-';
      }

      const reports = [
        SCAN_TYPES.some((type) => this.mr.enabledReports?.[type]),
        this.hasLicenseComplianceReports,
        this.hasCodeQualityReports,
        this.hasBrowserPerformanceReports,
        this.hasLoadPerformanceReports,
        this.hasAccessibilityReports,
        this.hasMetricsReports,
        this.hasTestSummaryReports,
        this.hasTerraformReports,
        this.hasStatusChecksReports,
      ];

      return String(reports.filter(Boolean).length);
    },
    // Populated in a requestIdleCallback, so it can arrive after the count does.
    stickyHeaderTab() {
      return tabData.tabs?.find(([key]) => key === 'reports');
    },
  },
  watch: {
    text: 'syncStickyHeader',
    stickyHeaderTab: 'syncStickyHeader',
  },
  methods: {
    syncStickyHeader() {
      if (this.stickyHeaderTab) this.stickyHeaderTab[3] = this.text;
    },
  },
};
</script>

<template>
  <span class="js-reports-tab-count">{{ text }}</span>
</template>
