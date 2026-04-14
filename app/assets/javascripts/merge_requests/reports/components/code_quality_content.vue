<script>
import { s__ } from '~/locale';
import ReportSection from '~/merge_requests/reports/components/report_section.vue';
import { codeQualitySummary } from '~/vue_merge_request_widget/widgets/code_quality/utils';

export default {
  name: 'CodeQualityContent',
  components: {
    ReportSection,
  },
  inject: [
    'isCodeQualityLoading',
    'statusMessage',
    'errorMessage',
    'newErrorsCount',
    'resolvedErrorsCount',
    'statusIconName',
    'sections',
  ],
  i18n: {
    loading: s__('ciReport|Code quality is loading'),
  },
  computed: {
    summaryText() {
      if (this.statusMessage) {
        return this.statusMessage;
      }
      if (this.errorMessage) {
        return this.errorMessage;
      }

      return codeQualitySummary({
        newCount: this.newErrorsCount,
        resolvedCount: this.resolvedErrorsCount,
      });
    },
    summary() {
      return { title: this.summaryText };
    },
  },
};
</script>

<template>
  <report-section
    :is-loading="isCodeQualityLoading"
    :loading-text="$options.i18n.loading"
    :summary="summary"
    :status-icon-name="statusIconName"
    :sections="sections"
  />
</template>
