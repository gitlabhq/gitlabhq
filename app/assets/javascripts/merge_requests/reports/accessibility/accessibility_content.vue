<script>
import { s__ } from '~/locale';
import ReportSection from '~/merge_requests/reports/components/report_section.vue';
import { accessibilitySummaryText } from '~/vue_merge_request_widget/widgets/accessibility/utils';

export default {
  name: 'AccessibilityContent',
  components: {
    ReportSection,
  },
  inject: [
    'isAccessibilityLoading',
    'statusMessage',
    'errorMessage',
    'errorCount',
    'statusIconName',
    'sections',
  ],
  i18n: {
    loading: s__('Reports|Accessibility scanning results are being parsed'),
  },
  computed: {
    summary() {
      return {
        title: this.statusMessage || this.errorMessage || accessibilitySummaryText(this.errorCount),
      };
    },
  },
};
</script>

<template>
  <report-section
    :is-loading="isAccessibilityLoading"
    :loading-text="$options.i18n.loading"
    :summary="summary"
    :status-icon-name="statusIconName"
    :sections="sections"
  />
</template>
