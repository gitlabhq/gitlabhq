<script>
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import { SECURITY_SCAN_ROUTE } from '~/merge_requests/reports/constants';
import ReportListItem from '~/merge_requests/reports/components/report_list_item.vue';

export default {
  name: 'SecurityNavItem',
  components: {
    ReportListItem,
  },
  inject: ['totalNewFindings', 'isSecurityScansLoading', 'topLevelErrorMessage'],
  computed: {
    statusIcon() {
      if (this.topLevelErrorMessage) {
        return EXTENSION_ICONS.error;
      }
      if (this.totalNewFindings > 0) {
        return EXTENSION_ICONS.warning;
      }
      return EXTENSION_ICONS.success;
    },
  },
  routeNames: {
    SECURITY_SCAN_ROUTE,
  },
};
</script>

<template>
  <report-list-item
    :to="$options.routeNames.SECURITY_SCAN_ROUTE"
    :status-icon="statusIcon"
    :is-loading="isSecurityScansLoading"
  >
    {{ s__('MrReports|Security scan') }}
  </report-list-item>
</template>
