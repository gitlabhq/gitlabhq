<script>
import { TERRAFORM_ROUTE } from '~/merge_requests/reports/constants';
import ReportListItem from '~/merge_requests/reports/components/report_list_item.vue';

export default {
  name: 'TerraformNavItem',
  components: {
    ReportListItem,
  },
  inject: ['isTerraformLoading', 'statusIconName'],
  routeNames: {
    TERRAFORM_ROUTE,
  },
};
</script>

<template>
  <report-list-item
    :to="$options.routeNames.TERRAFORM_ROUTE"
    :status-icon="statusIconName"
    :is-loading="isTerraformLoading"
  >
    {{ s__('MrReports|Terraform') }}
  </report-list-item>
</template>
