<script>
import { CODE_QUALITY_ROUTE } from '~/merge_requests/reports/constants';
import ReportListItem from '~/merge_requests/reports/components/report_list_item.vue';

export default {
  name: 'CodeQualityNavItem',
  components: {
    ReportListItem,
  },
  inject: ['isCodeQualityLoading', 'statusIconName'],
  routeNames: {
    CODE_QUALITY_ROUTE,
  },
};
</script>

<template>
  <report-list-item
    :to="$options.routeNames.CODE_QUALITY_ROUTE"
    :status-icon="statusIconName"
    :is-loading="isCodeQualityLoading"
  >
    {{ s__('MrReports|Code quality') }}
  </report-list-item>
</template>
