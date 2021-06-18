<script>
import { mapActions, mapGetters } from 'vuex';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import ReportSection from '~/reports/components/report_section.vue';
import { ERROR, SLOT_SUCCESS, SLOT_LOADING, SLOT_ERROR } from '~/reports/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import HelpIcon from './components/help_icon.vue';
import SecurityReportDownloadDropdown from './components/security_report_download_dropdown.vue';
import SecuritySummary from './components/security_summary.vue';
import {
  REPORT_TYPE_SAST,
  REPORT_TYPE_SECRET_DETECTION,
  reportTypeToSecurityReportTypeEnum,
} from './constants';
import securityReportMergeRequestDownloadPathsQuery from './queries/security_report_merge_request_download_paths.query.graphql';
import store from './store';
import { MODULE_SAST, MODULE_SECRET_DETECTION } from './store/constants';
import { extractSecurityReportArtifactsFromMergeRequest } from './utils';

export default {
  store,
  components: {
    ReportSection,
    HelpIcon,
    SecurityReportDownloadDropdown,
    SecuritySummary,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    pipelineId: {
      type: Number,
      required: true,
    },
    projectId: {
      type: Number,
      required: true,
    },
    securityReportsDocsPath: {
      type: String,
      required: true,
    },
    discoverProjectSecurityPath: {
      type: String,
      required: false,
      default: '',
    },
    sastComparisonPath: {
      type: String,
      required: false,
      default: '',
    },
    secretScanningComparisonPath: {
      type: String,
      required: false,
      default: '',
    },
    targetProjectFullPath: {
      type: String,
      required: false,
      default: '',
    },
    mrIid: {
      type: Number,
      required: false,
      default: 0,
    },
    canDiscoverProjectSecurity: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      availableSecurityReports: [],
      canShowCounts: false,

      // When core_security_mr_widget_counts is not enabled, the
      // error state is shown even when successfully loaded, since success
      // state suggests that the security scans detected no security problems,
      // which is not necessarily the case. A future iteration will actually
      // check whether problems were found and display the appropriate status.
      status: ERROR,
    };
  },
  apollo: {
    reportArtifacts: {
      query: securityReportMergeRequestDownloadPathsQuery,
      variables() {
        return {
          projectPath: this.targetProjectFullPath,
          iid: String(this.mrIid),
          reportTypes: this.$options.reportTypes.map(
            (reportType) => reportTypeToSecurityReportTypeEnum[reportType],
          ),
        };
      },
      update(data) {
        return extractSecurityReportArtifactsFromMergeRequest(this.$options.reportTypes, data);
      },
      error(error) {
        this.showError(error);
      },
      result({ loading }) {
        if (loading) {
          return;
        }

        // Query has completed, so populate the availableSecurityReports.
        this.onCheckingAvailableSecurityReports(
          this.reportArtifacts.map(({ reportType }) => reportType),
        );
      },
    },
  },
  computed: {
    ...mapGetters(['groupedSummaryText', 'summaryStatus']),
    hasSecurityReports() {
      return this.availableSecurityReports.length > 0;
    },
    hasSastReports() {
      return this.availableSecurityReports.includes(REPORT_TYPE_SAST);
    },
    hasSecretDetectionReports() {
      return this.availableSecurityReports.includes(REPORT_TYPE_SECRET_DETECTION);
    },
    isLoadingReportArtifacts() {
      return this.$apollo.queries.reportArtifacts.loading;
    },
  },
  methods: {
    ...mapActions(MODULE_SAST, {
      setSastDiffEndpoint: 'setDiffEndpoint',
      fetchSastDiff: 'fetchDiff',
    }),
    ...mapActions(MODULE_SECRET_DETECTION, {
      setSecretDetectionDiffEndpoint: 'setDiffEndpoint',
      fetchSecretDetectionDiff: 'fetchDiff',
    }),
    fetchCounts() {
      if (!this.glFeatures.coreSecurityMrWidgetCounts) {
        return;
      }

      if (this.sastComparisonPath && this.hasSastReports) {
        this.setSastDiffEndpoint(this.sastComparisonPath);
        this.fetchSastDiff();
        this.canShowCounts = true;
      }

      if (this.secretScanningComparisonPath && this.hasSecretDetectionReports) {
        this.setSecretDetectionDiffEndpoint(this.secretScanningComparisonPath);
        this.fetchSecretDetectionDiff();
        this.canShowCounts = true;
      }
    },
    onCheckingAvailableSecurityReports(availableSecurityReports) {
      this.availableSecurityReports = availableSecurityReports;
      this.fetchCounts();
    },
    showError(error) {
      createFlash({
        message: this.$options.i18n.apiError,
        captureError: true,
        error,
      });
    },
  },
  reportTypes: [REPORT_TYPE_SAST, REPORT_TYPE_SECRET_DETECTION],
  i18n: {
    apiError: s__(
      'SecurityReports|Failed to get security report information. Please reload the page or try again later.',
    ),
    scansHaveRun: s__('SecurityReports|Security scans have run'),
  },
  summarySlots: [SLOT_SUCCESS, SLOT_LOADING, SLOT_ERROR],
};
</script>
<template>
  <report-section
    v-if="canShowCounts"
    :status="summaryStatus"
    :has-issues="false"
    class="mr-widget-border-top mr-report"
    data-testid="security-mr-widget"
    track-action="users_expanding_secure_security_report"
  >
    <template v-for="slot in $options.summarySlots" #[slot]>
      <span :key="slot">
        <security-summary :message="groupedSummaryText" />

        <help-icon
          class="gl-ml-3"
          :help-path="securityReportsDocsPath"
          :discover-project-security-path="discoverProjectSecurityPath"
        />
      </span>
    </template>

    <template #action-buttons>
      <security-report-download-dropdown
        :text="s__('SecurityReports|Download results')"
        :artifacts="reportArtifacts"
        :loading="isLoadingReportArtifacts"
      />
    </template>
  </report-section>

  <!-- TODO: Remove this section when removing core_security_mr_widget_counts
    feature flag. See https://gitlab.com/gitlab-org/gitlab/-/issues/284097 -->
  <report-section
    v-else-if="hasSecurityReports"
    :status="status"
    :has-issues="false"
    class="mr-widget-border-top mr-report"
    data-testid="security-mr-widget"
    track-action="users_expanding_secure_security_report"
  >
    <template #error>
      {{ $options.i18n.scansHaveRun }}

      <help-icon
        class="gl-ml-3"
        :help-path="securityReportsDocsPath"
        :discover-project-security-path="discoverProjectSecurityPath"
      />
    </template>

    <template #action-buttons>
      <security-report-download-dropdown
        :text="s__('SecurityReports|Download results')"
        :artifacts="reportArtifacts"
        :loading="isLoadingReportArtifacts"
      />
    </template>
  </report-section>
</template>
