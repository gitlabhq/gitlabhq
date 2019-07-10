<script>
import { mapState } from 'vuex';
import _ from 'underscore';
import MonitorAreaChart from './charts/area.vue';
import MonitorSingleStatChart from './charts/single_stat.vue';

export default {
  components: {
    MonitorAreaChart,
    MonitorSingleStatChart,
  },
  props: {
    graphData: {
      type: Object,
      required: true,
    },
    dashboardWidth: {
      type: Number,
      required: true,
    },
  },
  computed: {
    ...mapState('monitoringDashboard', ['deploymentData', 'projectPath']),
    alertWidgetAvailable() {
      return IS_EE && this.prometheusAlertsAvailable && this.alertsEndpoint && this.graphData;
    },
  },
  methods: {
    getGraphAlerts(queries) {
      if (!this.allAlerts) return {};
      const metricIdsForChart = queries.map(q => q.metricId);
      return _.pick(this.allAlerts, alert => metricIdsForChart.includes(alert.metricId));
    },
    getGraphAlertValues(queries) {
      return Object.values(this.getGraphAlerts(queries));
    },
    isPanelType(type) {
      return this.graphData.type && this.graphData.type === type;
    },
  },
};
</script>
<template>
  <monitor-single-stat-chart v-if="isPanelType('single-stat')" :graph-data="graphData" />
  <monitor-area-chart
    v-else
    :graph-data="graphData"
    :deployment-data="deploymentData"
    :project-path="projectPath"
    :thresholds="getGraphAlertValues(graphData.queries)"
    :container-width="dashboardWidth"
    group-id="monitor-area-chart"
  >
    <alert-widget
      v-if="alertWidgetAvailable"
      :alerts-endpoint="alertsEndpoint"
      :relevant-queries="graphData.queries"
      :alerts-to-manage="getGraphAlerts(graphData.queries)"
      @setAlerts="setAlerts"
    />
  </monitor-area-chart>
</template>
