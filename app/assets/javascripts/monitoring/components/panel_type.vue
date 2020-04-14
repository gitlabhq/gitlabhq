<script>
import { mapState } from 'vuex';
import { pickBy } from 'lodash';
import invalidUrl from '~/lib/utils/invalid_url';
import {
  GlResizeObserverDirective,
  GlLoadingIcon,
  GlDropdown,
  GlDropdownItem,
  GlModal,
  GlModalDirective,
  GlTooltip,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __, n__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import MonitorTimeSeriesChart from './charts/time_series.vue';
import MonitorAnomalyChart from './charts/anomaly.vue';
import MonitorSingleStatChart from './charts/single_stat.vue';
import MonitorHeatmapChart from './charts/heatmap.vue';
import MonitorColumnChart from './charts/column.vue';
import MonitorBarChart from './charts/bar.vue';
import MonitorStackedColumnChart from './charts/stacked_column.vue';
import MonitorEmptyChart from './charts/empty_chart.vue';
import TrackEventDirective from '~/vue_shared/directives/track_event';
import { timeRangeToUrl, downloadCSVOptions, generateLinkToChartOptions } from '../utils';

const events = {
  timeRangeZoom: 'timerangezoom',
};

export default {
  components: {
    MonitorSingleStatChart,
    MonitorColumnChart,
    MonitorBarChart,
    MonitorHeatmapChart,
    MonitorStackedColumnChart,
    MonitorEmptyChart,
    Icon,
    GlLoadingIcon,
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
    namespace: {
      type: String,
      required: false,
      default: 'monitoringDashboard',
    },
  },
  data() {
    return {
      showTitleTooltip: false,
      zoomedTimeRange: null,
    };
  },
  computed: {
    // Use functions to support dynamic namespaces in mapXXX helpers. Pattern described
    // in https://github.com/vuejs/vuex/issues/863#issuecomment-329510765
    ...mapState({
      deploymentData(state) {
        return state[this.namespace].deploymentData;
      },
      projectPath(state) {
        return state[this.namespace].projectPath;
      },
      logsPath(state) {
        return state[this.namespace].logsPath;
      },
      timeRange(state) {
        return state[this.namespace].timeRange;
      },
    }),
    title() {
      return this.graphData.title || '';
    },
    alertWidgetAvailable() {
      // This method is extended by ee functionality
      return false;
    },
    graphDataHasResult() {
      return (
        this.graphData.metrics &&
        this.graphData.metrics[0].result &&
        this.graphData.metrics[0].result.length > 0
      );
    },
    graphDataIsLoading() {
      const { metrics = [] } = this.graphData;
      return metrics.some(({ loading }) => loading);
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
      const header = `timestamp,${yLabel}\r\n`; // eslint-disable-line @gitlab/require-i18n-strings
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
        this.graphDataHasResult &&
        !this.isPanelType('single-stat') &&
        !this.isPanelType('heatmap') &&
        !this.isPanelType('column') &&
        !this.isPanelType('stacked-column')
      );
    },
    editCustomMetricLink() {
      return this.graphData?.metrics[0].edit_path;
    },
    editCustomMetricLinkText() {
      return n__('Metrics|Edit metric', 'Metrics|Edit metrics', this.graphData.metrics.length);
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
      this.$emit(events.timeRangeZoom, { start, end });
    },
  },
};
</script>
<template>
  <div v-gl-resize-observer="onResize" class="prometheus-graph">
    <div class="d-flex align-items-center mr-3">
      <h5
        ref="graphTitle"
        class="prometheus-graph-title gl-font-size-large font-weight-bold text-truncate append-right-8"
      >
        {{ title }}
      </h5>
      <gl-tooltip :target="() => $refs.graphTitle" :disabled="!showTitleTooltip">
        {{ title }}
      </gl-tooltip>
      <alert-widget
        v-if="isContextualMenuShown && alertWidgetAvailable"
        class="mx-1"
        :modal-id="`alert-modal-${index}`"
        :alerts-endpoint="alertsEndpoint"
        :relevant-queries="graphData.metrics"
        :alerts-to-manage="getGraphAlerts(graphData.metrics)"
        @setAlerts="setAlerts"
      />
      <div class="flex-grow-1"></div>
      <div v-if="graphDataIsLoading" class="mx-1 mt-1">
        <gl-loading-icon />
      </div>
      <div
        v-if="isContextualMenuShown"
        class="js-graph-widgets"
        data-qa-selector="prometheus_graph_widgets"
      >
        <div class="d-flex align-items-center">
          <gl-dropdown
            v-gl-tooltip
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
              v-if="editCustomMetricLink"
              ref="editMetricLink"
              :href="editCustomMetricLink"
            >
              {{ editCustomMetricLinkText }}
            </gl-dropdown-item>
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
              {{ __('Copy link to chart') }}
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
      v-if="isPanelType('single-stat') && graphDataHasResult"
      :graph-data="graphData"
    />
    <monitor-heatmap-chart
      v-else-if="isPanelType('heatmap') && graphDataHasResult"
      :graph-data="graphData"
    />
    <monitor-bar-chart
      v-else-if="isPanelType('bar') && graphDataHasResult"
      :graph-data="graphData"
    />
    <monitor-column-chart
      v-else-if="isPanelType('column') && graphDataHasResult"
      :graph-data="graphData"
    />
    <monitor-stacked-column-chart
      v-else-if="isPanelType('stacked-column') && graphDataHasResult"
      :graph-data="graphData"
    />
    <component
      :is="timeChartComponent"
      v-else-if="graphDataHasResult"
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
