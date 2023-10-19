<script>
import { GlAlert } from '@gitlab/ui';

import { getGlobalAlerts, setGlobalAlerts, removeGlobalAlertById } from '~/lib/utils/global_alerts';

export default {
  name: 'GlobalAlerts',
  components: { GlAlert },
  data() {
    return {
      alerts: [],
    };
  },
  mounted() {
    const { page } = document.body.dataset;
    const alerts = getGlobalAlerts();

    const alertsToPersist = alerts.filter((alert) => alert.persistOnPages.length);
    const alertsToRender = alerts.filter(
      (alert) => alert.persistOnPages.length === 0 || alert.persistOnPages.includes(page),
    );

    this.alerts = alertsToRender;

    // Once we render the global alerts, we re-set the global alerts to only store persistent alerts for the next load.
    setGlobalAlerts(alertsToPersist);
  },
  methods: {
    onDismiss(index) {
      const alert = this.alerts[index];
      this.alerts.splice(index, 1);
      removeGlobalAlertById(alert.id);
    },
  },
};
</script>

<template>
  <div v-if="alerts.length">
    <gl-alert
      v-for="(alert, index) in alerts"
      :key="alert.id"
      :variant="alert.variant"
      :title="alert.title"
      :dismissible="alert.dismissible"
      @dismiss="onDismiss(index)"
      >{{ alert.message }}</gl-alert
    >
  </div>
</template>
