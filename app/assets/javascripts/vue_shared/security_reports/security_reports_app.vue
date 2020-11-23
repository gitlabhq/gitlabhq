<script>
import { mapActions, mapGetters } from 'vuex';
import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ReportSection from '~/reports/components/report_section.vue';
import { LOADING, ERROR, SLOT_SUCCESS, SLOT_LOADING, SLOT_ERROR } from '~/reports/constants';
import { s__ } from '~/locale';
import { normalizeHeaders, parseIntPagination } from '~/lib/utils/common_utils';
import createFlash from '~/flash';
import Api from '~/api';
import SecuritySummary from './components/security_summary.vue';
import store from './store';
import { MODULE_SAST, MODULE_SECRET_DETECTION } from './store/constants';
import { REPORT_TYPE_SAST, REPORT_TYPE_SECRET_DETECTION } from './constants';

export default {
  store,
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
    ReportSection,
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
    isLoaded() {
      return this.summaryStatus !== LOADING;
    },
  },
  created() {
    this.checkAvailableSecurityReports(this.$options.reportTypes)
      .then(availableSecurityReports => {
        this.availableSecurityReports = Array.from(availableSecurityReports);
        this.fetchCounts();
      })
      .catch(error => {
        createFlash({
          message: this.$options.i18n.apiError,
          captureError: true,
          error,
        });
      });
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
  },
  reportTypes: [REPORT_TYPE_SAST, REPORT_TYPE_SECRET_DETECTION],
  i18n: {
    apiError: s__(
      'SecurityReports|Failed to get security report information. Please reload the page or try again later.',
    ),
    scansHaveRun: s__(
      'SecurityReports|Security scans have run. Go to the %{linkStart}pipelines tab%{linkEnd} to download the security reports',
    ),
    downloadFromPipelineTab: s__(
      'SecurityReports|Go to the %{linkStart}pipelines tab%{linkEnd} to download the security reports',
    ),
    securityReportsHelp: s__('SecurityReports|Security reports help page link'),
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

        <gl-link
          target="_blank"
          data-testid="help"
          :href="securityReportsDocsPath"
          :aria-label="$options.i18n.securityReportsHelp"
        >
          <gl-icon name="question" />
        </gl-link>
      </span>
    </template>

    <template v-if="isLoaded" #sub-heading>
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
      <gl-sprintf :message="$options.i18n.scansHaveRun">
        <template #link="{ content }">
          <gl-link data-testid="show-pipelines" @click="activatePipelinesTab">{{
            content
          }}</gl-link>
        </template>
      </gl-sprintf>

      <gl-link
        target="_blank"
        data-testid="help"
        :href="securityReportsDocsPath"
        :aria-label="$options.i18n.securityReportsHelp"
      >
        <gl-icon name="question" />
      </gl-link>
    </template>
  </report-section>
</template>
