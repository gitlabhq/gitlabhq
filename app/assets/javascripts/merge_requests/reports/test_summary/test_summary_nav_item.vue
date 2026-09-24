<script>
import { TEST_SUMMARY_ROUTE } from '~/merge_requests/reports/constants';
import ReportListItem from '~/merge_requests/reports/components/report_list_item.vue';

export default {
  name: 'TestSummaryNavItem',
  components: {
    ReportListItem,
  },
  inject: ['isTestSummaryLoading', 'statusIconName'],
  routeNames: {
    TEST_SUMMARY_ROUTE,
  },
};
</script>

<template>
  <report-list-item
    :to="$options.routeNames.TEST_SUMMARY_ROUTE"
    :status-icon="statusIconName"
    :is-loading="isTestSummaryLoading"
  >
    {{ s__('MrReports|Test summary') }}
  </report-list-item>
</template>
