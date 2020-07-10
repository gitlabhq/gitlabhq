<script>
import Tracking from '~/tracking';
import { trackAlertListViewsOptions } from '../constants';
import AlertManagementEmptyState from './alert_management_empty_state.vue';
import AlertManagementTable from './alert_management_table.vue';

export default {
  components: {
    AlertManagementEmptyState,
    AlertManagementTable,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    alertManagementEnabled: {
      type: Boolean,
      required: true,
    },
    enableAlertManagementPath: {
      type: String,
      required: true,
    },
    populatingAlertsHelpUrl: {
      type: String,
      required: true,
    },
    userCanEnableAlertManagement: {
      type: Boolean,
      required: true,
    },
    emptyAlertSvgPath: {
      type: String,
      required: true,
    },
  },
  mounted() {
    this.trackPageViews();
  },
  methods: {
    trackPageViews() {
      const { category, action } = trackAlertListViewsOptions;
      Tracking.event(category, action);
    },
  },
};
</script>
<template>
  <div>
    <alert-management-table
      v-if="alertManagementEnabled"
      :populating-alerts-help-url="populatingAlertsHelpUrl"
      :project-path="projectPath"
    />
    <alert-management-empty-state
      v-else
      :empty-alert-svg-path="emptyAlertSvgPath"
      :enable-alert-management-path="enableAlertManagementPath"
      :user-can-enable-alert-management="userCanEnableAlertManagement"
    />
  </div>
</template>
