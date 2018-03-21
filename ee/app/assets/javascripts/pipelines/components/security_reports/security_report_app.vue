<script>
  import ReportSection from 'ee/vue_shared/security_reports/components/report_section.vue';
  import securityMixin from 'ee/vue_shared/security_reports/mixins/security_report_mixin';
  import LoadingIcon from '~/vue_shared/components/loading_icon.vue';
  import { SAST } from 'ee/vue_shared/security_reports/helpers/constants';

  export default {
    name: 'SecurityReportTab',
    components: {
      LoadingIcon,
      ReportSection,
    },
    mixins: [securityMixin],
    sast: SAST,
    props: {
      securityReports: {
        type: Object,
        required: true,
      },
      hasDependencyScanning: {
        type: Boolean,
        required: false,
        default: false,
      },
      hasSast: {
        type: Boolean,
        required: false,
        default: false,
      },
    },
  };
</script>
<template>
  <div class="pipeline-tab-content">
    <report-section
      v-if="hasSast"
      class="js-sast-widget"
      :type="$options.sast"
      :status="checkReportStatus(securityReports.sast.isLoading, securityReports.sast.hasError)"
      :loading-text="translateText('security').loading"
      :error-text="translateText('security').error"
      :success-text="sastText(securityReports.sast.newIssues, securityReports.sast.resolvedIssues)"
      :unresolved-issues="securityReports.sast.newIssues"
      :resolved-issues="securityReports.sast.resolvedIssues"
      :all-issues="securityReports.sast.allIssues"
    />

    <report-section
      v-if="hasDependencyScanning"
      class="js-dependency-scanning-widget"
      :class="{ 'prepend-top-20': hasSast }"
      :type="$options.sast"
      :status="checkReportStatus(
        securityReports.dependencyScanning.isLoading,
        securityReports.dependencyScanning.hasError
      )"
      :loading-text="translateText('dependency scanning').loading"
      :error-text="translateText('dependency scanning').error"
      :success-text="depedencyScanningText(
        securityReports.dependencyScanning.newIssues,
        securityReports.dependencyScanning.resolvedIssues
      )"
      :unresolved-issues="securityReports.dependencyScanning.newIssues"
      :resolved-issues="securityReports.dependencyScanning.resolvedIssues"
      :all-issues="securityReports.dependencyScanning.allIssues"
    />
  </div>
</template>
