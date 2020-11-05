<script>
import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import ReportSection from '~/reports/components/report_section.vue';
import { status } from '~/reports/constants';
import { s__ } from '~/locale';
import { normalizeHeaders, parseIntPagination } from '~/lib/utils/common_utils';
import Flash from '~/flash';
import Api from '~/api';

export default {
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
    ReportSection,
  },
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
  },
  data() {
    return {
      hasSecurityReports: false,

      // Error state is shown even when successfully loaded, since success
      // state suggests that the security scans detected no security problems,
      // which is not necessarily the case. A future iteration will actually
      // check whether problems were found and display the appropriate status.
      status: status.ERROR,
    };
  },
  created() {
    this.checkHasSecurityReports(this.$options.reportTypes)
      .then(hasSecurityReports => {
        this.hasSecurityReports = hasSecurityReports;
      })
      .catch(error => {
        Flash({
          message: this.$options.i18n.apiError,
          captureError: true,
          error,
        });
      });
  },
  methods: {
    async checkHasSecurityReports(reportTypes) {
      let page = 1;
      while (page) {
        // eslint-disable-next-line no-await-in-loop
        const { data: jobs, headers } = await Api.pipelineJobs(this.projectId, this.pipelineId, {
          per_page: 100,
          page,
        });

        const hasSecurityReports = jobs.some(({ artifacts = [] }) =>
          artifacts.some(({ file_type }) => reportTypes.includes(file_type)),
        );

        if (hasSecurityReports) {
          return true;
        }

        page = parseIntPagination(normalizeHeaders(headers)).nextPage;
      }

      return false;
    },
    activatePipelinesTab() {
      if (window.mrTabs) {
        window.mrTabs.tabShown('pipelines');
      }
    },
  },
  reportTypes: ['sast', 'secret_detection'],
  i18n: {
    apiError: s__(
      'SecurityReports|Failed to get security report information. Please reload the page or try again later.',
    ),
    scansHaveRun: s__(
      'SecurityReports|Security scans have run. Go to the %{linkStart}pipelines tab%{linkEnd} to download the security reports',
    ),
    securityReportsHelp: s__('SecurityReports|Security reports help page link'),
  },
};
</script>
<template>
  <report-section
    v-if="hasSecurityReports"
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
