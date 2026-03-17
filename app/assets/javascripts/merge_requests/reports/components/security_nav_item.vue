<script>
import { SECURITY_SCAN_ROUTE } from '~/merge_requests/reports/constants';
import ReportListItem from '~/merge_requests/reports/components/report_list_item.vue';

export default {
  name: 'SecurityNavItem',
  components: {
    ReportListItem,
  },
  inject: ['isLoadingScans', 'statusIconName'],
  routeNames: {
    SECURITY_SCAN_ROUTE,
  },
};
</script>

<template>
  <report-list-item
    :to="$options.routeNames.SECURITY_SCAN_ROUTE"
    :status-icon="statusIconName"
    :is-loading="isLoadingScans"
  >
    {{ s__('MrReports|Security scan') }}
  </report-list-item>
</template>
