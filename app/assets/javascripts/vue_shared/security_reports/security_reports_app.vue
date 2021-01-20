<script>
import { mapActions, mapGetters } from 'vuex';
import { GlLink, GlSprintf } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ReportSection from '~/reports/components/report_section.vue';
import { LOADING, ERROR, SLOT_SUCCESS, SLOT_LOADING, SLOT_ERROR } from '~/reports/constants';
import { s__ } from '~/locale';
import { normalizeHeaders, parseIntPagination } from '~/lib/utils/common_utils';
import createFlash from '~/flash';
import Api from '~/api';
import HelpIcon from './components/help_icon.vue';
import SecurityReportDownloadDropdown from './components/security_report_download_dropdown.vue';
import SecuritySummary from './components/security_summary.vue';
import store from './store';
import { MODULE_SAST, MODULE_SECRET_DETECTION } from './store/constants';
import {
  REPORT_TYPE_SAST,
  REPORT_TYPE_SECRET_DETECTION,
  reportTypeToSecurityReportTypeEnum,
} from './constants';
import securityReportDownloadPathsQuery from './queries/security_report_download_paths.query.graphql';
import { extractSecurityReportArtifacts } from './utils';

export default {
  store,
  components: {
    GlLink,
    GlSprintf,
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
      query: securityReportDownloadPathsQuery,
      variables() {
        return {
          projectPath: this.targetProjectFullPath,
          iid: String(this.mrIid),
          reportTypes: this.$options.reportTypes.map(
            (reportType) => reportTypeToSecurityReportTypeEnum[reportType],
          ),
        };
      },
      skip() {
        return !this.canShowDownloads;
      },
      update(data) {
        return extractSecurityReportArtifacts(this.$options.reportTypes, data);
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
    canShowDownloads() {
      return this.glFeatures.coreSecurityMrWidgetDownloads;
    },
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
    shouldShowDownloadGuidance() {
      return !this.canShowDownloads && this.summaryStatus !== LOADING;
    },
    scansHaveRunMessage() {
      return this.canShowDownloads
        ? this.$options.i18n.scansHaveRun
        : this.$options.i18n.scansHaveRunWithDownloadGuidance;
    },
  },
  created() {
    if (!this.canShowDownloads) {
      this.checkAvailableSecurityReports(this.$options.reportTypes)
        .then((availableSecurityReports) => {
          this.onCheckingAvailableSecurityReports(Array.from(availableSecurityReports));
        })
        .catch(this.showError);
    }
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
    async checkAvailableSecurityReports(reportTypes) {
      const reportTypesSet = new Set(reportTypes);
      const availableReportTypes = new Set();

      let page = 1;
      while (page) {
        // eslint-disable-next-line no-await-in-loop
        const { data: jobs, headers } = await Api.pipelineJobs(this.projectId, this.pipelineId, {
          per_page: 100,
          page,
        });

        jobs.forEach(({ artifacts = [] }) => {
          artifacts.forEach(({ file_type }) => {
            if (reportTypesSet.has(file_type)) {
              availableReportTypes.add(file_type);
            }
          });
        });

        // If we've found artifacts for all the report types, stop looking!
        if (availableReportTypes.size === reportTypesSet.size) {
          return availableReportTypes;
        }

        page = parseIntPagination(normalizeHeaders(headers)).nextPage;
      }

      return availableReportTypes;
    },
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
    activatePipelinesTab() {
      if (window.mrTabs) {
        window.mrTabs.tabShown('pipelines');
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
    scansHaveRunWithDownloadGuidance: s__(
      'SecurityReports|Security scans have run. Go to the %{linkStart}pipelines tab%{linkEnd} to download the security reports',
    ),
    downloadFromPipelineTab: s__(
      'SecurityReports|Go to the %{linkStart}pipelines tab%{linkEnd} to download the security reports',
    ),
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
  >
    <template v-for="slot in $options.summarySlots" #[slot]>
      <span :key="slot">
        <security-summary :message="groupedSummaryText" />

        <help-icon
          :help-path="securityReportsDocsPath"
          :discover-project-security-path="discoverProjectSecurityPath"
        />
      </span>
    </template>

    <template v-if="shouldShowDownloadGuidance" #sub-heading>
      <span class="gl-font-sm">
        <gl-sprintf :message="$options.i18n.downloadFromPipelineTab">
          <template #link="{ content }">
            <gl-link
              class="gl-font-sm"
              data-testid="show-pipelines"
              @click="activatePipelinesTab"
              >{{ content }}</gl-link
            >
          </template>
        </gl-sprintf>
      </span>
    </template>

    <template v-if="canShowDownloads" #action-buttons>
      <security-report-download-dropdown
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
  >
    <template #error>
      <gl-sprintf :message="scansHaveRunMessage">
        <template #link="{ content }">
          <gl-link data-testid="show-pipelines" @click="activatePipelinesTab">{{
            content
          }}</gl-link>
        </template>
      </gl-sprintf>

      <help-icon
        :help-path="securityReportsDocsPath"
        :discover-project-security-path="discoverProjectSecurityPath"
      />
    </template>

    <template v-if="canShowDownloads" #action-buttons>
      <security-report-download-dropdown
        :artifacts="reportArtifacts"
        :loading="isLoadingReportArtifacts"
      />
    </template>
  </report-section>
</template>
