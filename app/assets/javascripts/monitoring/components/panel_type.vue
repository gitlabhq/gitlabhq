<script>
import { mapState } from 'vuex';
import _ from 'underscore';
import { __ } from '~/locale';
import {
  GlDropdown,
  GlDropdownItem,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
} from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import MonitorTimeSeriesChart from './charts/time_series.vue';
import MonitorSingleStatChart from './charts/single_stat.vue';
import MonitorEmptyChart from './charts/empty_chart.vue';

export default {
  components: {
    MonitorSingleStatChart,
    MonitorTimeSeriesChart,
    MonitorEmptyChart,
    Icon,
    GlDropdown,
    GlDropdownItem,
    GlModal,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  props: {
    clipboardText: {
      type: String,
      required: true,
    },
    graphData: {
      type: Object,
      required: true,
    },
    dashboardWidth: {
      type: Number,
      required: true,
    },
    index: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapState('monitoringDashboard', ['deploymentData', 'projectPath']),
    alertWidgetAvailable() {
      return IS_EE && this.prometheusAlertsAvailable && this.alertsEndpoint && this.graphData;
    },
    graphDataHasMetrics() {
      return this.graphData.queries[0].result.length > 0;
    },
    csvText() {
      const chartData = this.graphData.queries[0].result[0].values;
      const yLabel = this.graphData.y_label;
      const header = `timestamp,${yLabel}\r\n`; // eslint-disable-line @gitlab/i18n/no-non-i18n-strings
      return chartData.reduce((csv, data) => {
        const row = data.join(',');
        return `${csv}${row}\r\n`;
      }, header);
    },
    downloadCsv() {
      const data = new Blob([this.csvText], { type: 'text/plain' });
      return window.URL.createObjectURL(data);
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
    showToast() {
      this.$toast.show(__('Link copied to clipboard'));
    },
  },
};
</script>
<template>
  <monitor-single-stat-chart
    v-if="isPanelType('single-stat') && graphDataHasMetrics"
    :graph-data="graphData"
  />
  <monitor-time-series-chart
    v-else-if="graphDataHasMetrics"
    :graph-data="graphData"
    :deployment-data="deploymentData"
    :project-path="projectPath"
    :thresholds="getGraphAlertValues(graphData.queries)"
    :container-width="dashboardWidth"
    group-id="monitor-area-chart"
  >
    <div class="d-flex align-items-center">
      <alert-widget
        v-if="alertWidgetAvailable && graphData"
        :modal-id="`alert-modal-${index}`"
        :alerts-endpoint="alertsEndpoint"
        :relevant-queries="graphData.queries"
        :alerts-to-manage="getGraphAlerts(graphData.queries)"
        @setAlerts="setAlerts"
      />
      <gl-dropdown
        v-gl-tooltip
        class="mx-2"
        toggle-class="btn btn-transparent border-0"
        :right="true"
        :no-caret="true"
        :title="__('More actions')"
      >
        <template slot="button-content">
          <icon name="ellipsis_v" class="text-secondary" />
        </template>
        <gl-dropdown-item :href="downloadCsv" download="chart_metrics.csv">
          {{ __('Download CSV') }}
        </gl-dropdown-item>
        <gl-dropdown-item
          class="js-chart-link"
          :data-clipboard-text="clipboardText"
          @click="showToast"
        >
          {{ __('Generate link to chart') }}
        </gl-dropdown-item>
        <gl-dropdown-item v-if="alertWidgetAvailable" v-gl-modal="`alert-modal-${index}`">
          {{ __('Alerts') }}
        </gl-dropdown-item>
      </gl-dropdown>
    </div>
  </monitor-time-series-chart>
  <monitor-empty-chart v-else :graph-title="graphData.title" />
</template>
