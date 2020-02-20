<script>
import { mapState } from 'vuex';
import { pickBy } from 'lodash';
import invalidUrl from '~/lib/utils/invalid_url';
import {
  GlResizeObserverDirective,
  GlDropdown,
  GlDropdownItem,
  GlModal,
  GlModalDirective,
  GlTooltip,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import MonitorTimeSeriesChart from './charts/time_series.vue';
import MonitorAnomalyChart from './charts/anomaly.vue';
import MonitorSingleStatChart from './charts/single_stat.vue';
import MonitorHeatmapChart from './charts/heatmap.vue';
import MonitorColumnChart from './charts/column.vue';
import MonitorStackedColumnChart from './charts/stacked_column.vue';
import MonitorEmptyChart from './charts/empty_chart.vue';
import TrackEventDirective from '~/vue_shared/directives/track_event';
import { timeRangeToUrl, downloadCSVOptions, generateLinkToChartOptions } from '../utils';

export default {
  components: {
    MonitorSingleStatChart,
    MonitorColumnChart,
    MonitorHeatmapChart,
    MonitorStackedColumnChart,
    MonitorEmptyChart,
    Icon,
    GlTooltip,
    GlDropdown,
    GlDropdownItem,
    GlModal,
  },
  directives: {
    GlResizeObserver: GlResizeObserverDirective,
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
    TrackEvent: TrackEventDirective,
  },
  props: {
    clipboardText: {
      type: String,
      required: false,
      default: '',
    },
    graphData: {
      type: Object,
      required: true,
    },
    index: {
      type: String,
      required: false,
      default: '',
    },
    groupId: {
      type: String,
      required: false,
      default: 'panel-type-chart',
    },
  },
  data() {
    return {
      showTitleTooltip: false,
      zoomedTimeRange: null,
    };
  },
  computed: {
    ...mapState('monitoringDashboard', ['deploymentData', 'projectPath', 'logsPath', 'timeRange']),
    title() {
      return this.graphData.title || '';
    },
    alertWidgetAvailable() {
      return IS_EE && this.prometheusAlertsAvailable && this.alertsEndpoint && this.graphData;
    },
    graphDataHasMetrics() {
      return (
        this.graphData.metrics &&
        this.graphData.metrics[0].result &&
        this.graphData.metrics[0].result.length > 0
      );
    },
    logsPathWithTimeRange() {
      const timeRange = this.zoomedTimeRange || this.timeRange;

      if (this.logsPath && this.logsPath !== invalidUrl && timeRange) {
        return timeRangeToUrl(timeRange, this.logsPath);
      }
      return null;
    },
    csvText() {
      const chartData = this.graphData.metrics[0].result[0].values;
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
    timeChartComponent() {
      if (this.isPanelType('anomaly-chart')) {
        return MonitorAnomalyChart;
      }
      return MonitorTimeSeriesChart;
    },
    isContextualMenuShown() {
      return (
        this.graphDataHasMetrics &&
        !this.isPanelType('single-stat') &&
        !this.isPanelType('heatmap') &&
        !this.isPanelType('column') &&
        !this.isPanelType('stacked-column')
      );
    },
  },
  mounted() {
    this.refreshTitleTooltip();
  },
  methods: {
    getGraphAlerts(queries) {
      if (!this.allAlerts) return {};
      const metricIdsForChart = queries.map(q => q.metricId);
      return pickBy(this.allAlerts, alert => metricIdsForChart.includes(alert.metricId));
    },
    getGraphAlertValues(queries) {
      return Object.values(this.getGraphAlerts(queries));
    },
    isPanelType(type) {
      return this.graphData.type && this.graphData.type === type;
    },
    showToast() {
      this.$toast.show(__('Link copied'));
    },
    refreshTitleTooltip() {
      const { graphTitle } = this.$refs;
      this.showTitleTooltip =
        Boolean(graphTitle) && graphTitle.scrollWidth > graphTitle.offsetWidth;
    },

    downloadCSVOptions,
    generateLinkToChartOptions,

    onResize() {
      this.refreshTitleTooltip();
    },
    onDatazoom({ start, end }) {
      this.zoomedTimeRange = { start, end };
    },
  },
};
</script>
<template>
  <div v-gl-resize-observer="onResize" class="prometheus-graph">
    <div class="prometheus-graph-header">
      <h5
        ref="graphTitle"
        class="prometheus-graph-title gl-font-size-large font-weight-bold text-truncate append-right-8"
      >
        {{ title }}
      </h5>
      <gl-tooltip :target="() => $refs.graphTitle" :disabled="!showTitleTooltip">
        {{ title }}
      </gl-tooltip>
      <div
        v-if="isContextualMenuShown"
        class="prometheus-graph-widgets js-graph-widgets flex-fill"
        data-qa-selector="prometheus_graph_widgets"
      >
        <div class="d-flex align-items-center">
          <alert-widget
            v-if="alertWidgetAvailable && graphData"
            :modal-id="`alert-modal-${index}`"
            :alerts-endpoint="alertsEndpoint"
            :relevant-queries="graphData.metrics"
            :alerts-to-manage="getGraphAlerts(graphData.metrics)"
            @setAlerts="setAlerts"
          />
          <gl-dropdown
            v-gl-tooltip
            class="ml-auto mx-3"
            toggle-class="btn btn-transparent border-0"
            data-qa-selector="prometheus_widgets_dropdown"
            right
            no-caret
            :title="__('More actions')"
          >
            <template slot="button-content">
              <icon name="ellipsis_v" class="text-secondary" />
            </template>

            <gl-dropdown-item
              v-if="logsPathWithTimeRange"
              ref="viewLogsLink"
              :href="logsPathWithTimeRange"
            >
              {{ s__('Metrics|View logs') }}
            </gl-dropdown-item>

            <gl-dropdown-item
              v-if="csvText"
              ref="downloadCsvLink"
              v-track-event="downloadCSVOptions(title)"
              :href="downloadCsv"
              download="chart_metrics.csv"
            >
              {{ __('Download CSV') }}
            </gl-dropdown-item>
            <gl-dropdown-item
              v-if="clipboardText"
              ref="copyChartLink"
              v-track-event="generateLinkToChartOptions(clipboardText)"
              :data-clipboard-text="clipboardText"
              @click="showToast(clipboardText)"
            >
              {{ __('Generate link to chart') }}
            </gl-dropdown-item>
            <gl-dropdown-item
              v-if="alertWidgetAvailable"
              v-gl-modal="`alert-modal-${index}`"
              data-qa-selector="alert_widget_menu_item"
            >
              {{ __('Alerts') }}
            </gl-dropdown-item>
          </gl-dropdown>
        </div>
      </div>
    </div>

    <monitor-single-stat-chart
      v-if="isPanelType('single-stat') && graphDataHasMetrics"
      :graph-data="graphData"
    />
    <monitor-heatmap-chart
      v-else-if="isPanelType('heatmap') && graphDataHasMetrics"
      :graph-data="graphData"
    />
    <monitor-column-chart
      v-else-if="isPanelType('column') && graphDataHasMetrics"
      :graph-data="graphData"
    />
    <monitor-stacked-column-chart
      v-else-if="isPanelType('stacked-column') && graphDataHasMetrics"
      :graph-data="graphData"
    />
    <component
      :is="timeChartComponent"
      v-else-if="graphDataHasMetrics"
      ref="timeChart"
      :graph-data="graphData"
      :deployment-data="deploymentData"
      :project-path="projectPath"
      :thresholds="getGraphAlertValues(graphData.metrics)"
      :group-id="groupId"
      @datazoom="onDatazoom"
    />
    <monitor-empty-chart v-else :graph-title="title" v-bind="$attrs" v-on="$listeners" />
  </div>
</template>
