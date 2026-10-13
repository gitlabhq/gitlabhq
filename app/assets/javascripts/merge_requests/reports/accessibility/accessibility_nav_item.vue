<script>
import { ACCESSIBILITY_ROUTE } from '~/merge_requests/reports/constants';
import ReportListItem from '~/merge_requests/reports/components/report_list_item.vue';

export default {
  name: 'AccessibilityNavItem',
  components: {
    ReportListItem,
  },
  inject: ['isAccessibilityLoading', 'statusIconName'],
  routeNames: {
    ACCESSIBILITY_ROUTE,
  },
};
</script>

<template>
  <report-list-item
    :to="$options.routeNames.ACCESSIBILITY_ROUTE"
    :status-icon="statusIconName"
    :is-loading="isAccessibilityLoading"
  >
    {{ s__('MrReports|Accessibility') }}
  </report-list-item>
</template>
