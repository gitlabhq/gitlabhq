<script>
  import ReportSection from 'ee/vue_shared/security_reports/components/report_section.vue';
  import securityMixin from 'ee/vue_shared/security_reports/mixins/security_report_mixin';
  import LoadingIcon from '../../../vue_shared/components/loading_icon.vue';

  export default {
    name: 'SecurityReportTab',
    components: {
      LoadingIcon,
      ReportSection,
    },
    mixins: [
      securityMixin,
    ],
    props: {
      securityReports: {
        type: Object,
        required: true,
      },
    },
  };
</script>
<template>
  <div class="pipeline-tab-content">
    <report-section
      class="js-sast-widget"
      type="security"
      :status="checkReportStatus(securityReports.sast.isLoading, securityReports.sast.hasError)"
      :loading-text="translateText('security').loading"
      :error-text="translateText('security').error"
      :success-text="sastText(securityReports.sast.newIssues, securityReports.sast.resolvedIssues)"
      :unresolved-issues="securityReports.sast.newIssues"
      :resolved-issues="securityReports.sast.resolvedIssues"
      :all-issues="securityReports.sast.allIssues"
      :has-priority="true"
      :is-collapsible="false"
    />
  </div>
</template>
