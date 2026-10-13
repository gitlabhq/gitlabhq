<script>
import { s__ } from '~/locale';
import ReportSection from '~/merge_requests/reports/components/report_section.vue';

export default {
  name: 'TerraformContent',
  components: {
    ReportSection,
  },
  inject: ['isTerraformLoading', 'statusMessage', 'reportSummary', 'statusIconName', 'sections'],
  i18n: {
    loading: s__('Terraform|Loading Terraform reports…'),
  },
  computed: {
    summary() {
      return this.statusMessage ? { title: this.statusMessage } : this.reportSummary;
    },
  },
};
</script>

<template>
  <report-section
    :is-loading="isTerraformLoading"
    :loading-text="$options.i18n.loading"
    :summary="summary"
    :status-icon-name="statusIconName"
    :sections="sections"
  />
</template>
