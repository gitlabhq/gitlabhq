<script>
import { reportTypeToSecurityReportTypeEnum } from 'ee_else_ce/vue_shared/security_reports/constants';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import SecurityReportDownloadDropdown from '~/vue_shared/security_reports/components/security_report_download_dropdown.vue';
import securityReportMergeRequestDownloadPathsQuery from '~/vue_shared/security_reports/graphql/queries/security_report_merge_request_download_paths.query.graphql';
import { extractSecurityReportArtifactsFromMergeRequest } from '~/vue_shared/security_reports/utils';

export default {
  components: {
    SecurityReportDownloadDropdown,
  },
  props: {
    reportTypes: {
      type: Array,
      required: true,
      validator: (reportType) => {
        return reportType.every((report) => reportTypeToSecurityReportTypeEnum[report]);
      },
    },
    targetProjectFullPath: {
      type: String,
      required: true,
    },
    mrIid: {
      type: Number,
      required: true,
    },
    injectedArtifacts: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      reportArtifacts: [],
    };
  },
  apollo: {
    reportArtifacts: {
      query: securityReportMergeRequestDownloadPathsQuery,
      variables() {
        return {
          projectPath: this.targetProjectFullPath,
          iid: String(this.mrIid),
          reportTypes: this.reportTypes.map(
            (reportType) => reportTypeToSecurityReportTypeEnum[reportType],
          ),
        };
      },
      update(data) {
        return extractSecurityReportArtifactsFromMergeRequest(this.reportTypes, data);
      },
      error(error) {
        this.showError(error);
      },
    },
  },
  computed: {
    isLoadingReportArtifacts() {
      return this.$apollo.queries.reportArtifacts.loading;
    },
    mergedReportArtifacts() {
      return [...this.reportArtifacts, ...this.injectedArtifacts];
    },
  },
  methods: {
    showError(error) {
      createAlert({
        message: this.$options.i18n.apiError,
        captureError: true,
        error,
      });
    },
  },
  i18n: {
    apiError: s__(
      'SecurityReports|Failed to get security report information. Please reload the page or try again later.',
    ),
  },
};
</script>

<template>
  <security-report-download-dropdown
    :title="s__('SecurityReports|Download results')"
    :artifacts="mergedReportArtifacts"
    :loading="isLoadingReportArtifacts"
  />
</template>
