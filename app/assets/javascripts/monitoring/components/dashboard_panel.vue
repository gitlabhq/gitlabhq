<script>
import { mapState } from 'vuex';
import { pickBy } from 'lodash';
import invalidUrl from '~/lib/utils/invalid_url';
import {
  GlResizeObserverDirective,
  GlIcon,
  GlLoadingIcon,
  GlNewDropdown as GlDropdown,
  GlNewDropdownItem as GlDropdownItem,
  GlNewDropdownDivider as GlDropdownDivider,
  GlModal,
  GlModalDirective,
  GlTooltip,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __, n__ } from '~/locale';
import { panelTypes } from '../constants';

import MonitorEmptyChart from './charts/empty_chart.vue';
import MonitorTimeSeriesChart from './charts/time_series.vue';
import MonitorAnomalyChart from './charts/anomaly.vue';
import MonitorSingleStatChart from './charts/single_stat.vue';
import MonitorHeatmapChart from './charts/heatmap.vue';
import MonitorColumnChart from './charts/column.vue';
import MonitorBarChart from './charts/bar.vue';
import MonitorStackedColumnChart from './charts/stacked_column.vue';

import TrackEventDirective from '~/vue_shared/directives/track_event';
import AlertWidget from './alert_widget.vue';
import { timeRangeToUrl, downloadCSVOptions, generateLinkToChartOptions } from '../utils';
import { isSafeURL } from '~/lib/utils/url_utility';

const events = {
  timeRangeZoom: 'timerangezoom',
  expand: 'expand',
};

export default {
  components: {
    MonitorEmptyChart,
    AlertWidget,
    GlIcon,
    GlLoadingIcon,
    GlTooltip,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
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
      required: false,
      default: null,
    },
    groupId: {
      type: String,
      required: false,
      default: 'dashboard-panel',
    },
    namespace: {
      type: String,
      required: false,
      default: 'monitoringDashboard',
    },
    alertsEndpoint: {
      type: String,
      required: false,
      default: null,
    },
    prometheusAlertsAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    settingsPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      showTitleTooltip: false,
      zoomedTimeRange: null,
      allAlerts: {},
      expandBtnAvailable: Boolean(this.$listeners[events.expand]),
    };
  },
  computed: {
    // Use functions to support dynamic namespaces in mapXXX helpers. Pattern described
    // in https://github.com/vuejs/vuex/issues/863#issuecomment-329510765
    ...mapState({
      deploymentData(state) {
        return state[this.namespace].deploymentData;
      },
      annotations(state) {
        return state[this.namespace].annotations;
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
      metricsSavedToDb(state, getters) {
        return getters[`${this.namespace}/metricsSavedToDb`];
      },
      selectedDashboard(state, getters) {
        return getters[`${this.namespace}/selectedDashboard`];
      },
    }),
    title() {
      return this.graphData?.title || '';
    },
    graphDataHasResult() {
      return this.graphData?.metrics?.[0]?.result?.length > 0;
    },
    graphDataIsLoading() {
      const metrics = this.graphData?.metrics || [];
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
      const chartData = this.graphData?.metrics[0].result[0].values || [];
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

    /**
     * A chart is "basic" if it doesn't support
     * the same features as the TimeSeries based components
     * such as "annotations".
     *
     * @returns Vue Component wrapping a basic visualization
     */
    basicChartComponent() {
      if (this.isPanelType(panelTypes.SINGLE_STAT)) {
        return MonitorSingleStatChart;
      }
      if (this.isPanelType(panelTypes.HEATMAP)) {
        return MonitorHeatmapChart;
      }
      if (this.isPanelType(panelTypes.BAR)) {
        return MonitorBarChart;
      }
      if (this.isPanelType(panelTypes.COLUMN)) {
        return MonitorColumnChart;
      }
      if (this.isPanelType(panelTypes.STACKED_COLUMN)) {
        return MonitorStackedColumnChart;
      }
      if (this.isPanelType(panelTypes.ANOMALY_CHART)) {
        return MonitorAnomalyChart;
      }
      return null;
    },

    /**
     * In monitoring, Time Series charts typically support
     * a larger feature set like "annotations", "deployment
     * data", alert "thresholds" and "datazoom".
     *
     * This is intentional as Time Series are more frequently
     * used.
     *
     * @returns Vue Component wrapping a time series visualization,
     * Area Charts are rendered by default.
     */
    timeSeriesChartComponent() {
      if (this.isPanelType(panelTypes.ANOMALY_CHART)) {
        return MonitorAnomalyChart;
      }
      return MonitorTimeSeriesChart;
    },
    isContextualMenuShown() {
      return Boolean(this.graphDataHasResult && !this.basicChartComponent);
    },
    editCustomMetricLink() {
      if (this.graphData.metrics.length > 1) {
        return this.settingsPath;
      }
      return this.graphData?.metrics[0].edit_path;
    },
    editCustomMetricLinkText() {
      return n__('Metrics|Edit metric', 'Metrics|Edit metrics', this.graphData.metrics.length);
    },
    hasMetricsInDb() {
      const { metrics = [] } = this.graphData;
      return metrics.some(({ metricId }) => this.metricsSavedToDb.includes(metricId));
    },
    alertWidgetAvailable() {
      return (
        this.prometheusAlertsAvailable &&
        this.alertsEndpoint &&
        this.graphData &&
        this.hasMetricsInDb
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
      return this.graphData?.type === type;
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
    onExpand() {
      this.$emit(events.expand);
    },
    setAlerts(alertPath, alertAttributes) {
      if (alertAttributes) {
        this.$set(this.allAlerts, alertPath, alertAttributes);
      } else {
        this.$delete(this.allAlerts, alertPath);
      }
    },
    safeUrl(url) {
      return isSafeURL(url) ? url : '#';
    },
  },
  panelTypes,
};
</script>
<template>
  <div v-gl-resize-observer="onResize" class="prometheus-graph">
    <div class="d-flex align-items-center mr-3">
      <slot name="topLeft"></slot>
      <h5
        ref="graphTitle"
        class="prometheus-graph-title gl-font-lg font-weight-bold text-truncate gl-mr-3"
        tabindex="0"
      >
        {{ title }}
      </h5>
      <gl-tooltip :target="() => $refs.graphTitle" :disabled="!showTitleTooltip">
        {{ title }}
      </gl-tooltip>
      <alert-widget
        v-if="isContextualMenuShown && alertWidgetAvailable"
        class="mx-1"
        :modal-id="`alert-modal-${graphData.id}`"
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
        ref="contextualMenu"
        data-qa-selector="prometheus_graph_widgets"
      >
        <div class="d-flex align-items-center">
          <gl-dropdown
            v-gl-tooltip
            toggle-class="shadow-none border-0"
            data-qa-selector="prometheus_widgets_dropdown"
            right
            :title="__('More actions')"
          >
            <template slot="button-content">
              <gl-icon name="ellipsis_v" class="dropdown-icon text-secondary" />
            </template>
            <gl-dropdown-item
              v-if="expandBtnAvailable"
              ref="expandBtn"
              :href="clipboardText"
              @click.prevent="onExpand"
            >
              {{ s__('Metrics|Expand panel') }}
            </gl-dropdown-item>
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
              data-qa-selector="generate_chart_link_menu_item"
              @click="showToast(clipboardText)"
            >
              {{ __('Copy link to chart') }}
            </gl-dropdown-item>
            <gl-dropdown-item
              v-if="alertWidgetAvailable"
              v-gl-modal="`alert-modal-${graphData.id}`"
              data-qa-selector="alert_widget_menu_item"
            >
              {{ __('Alerts') }}
            </gl-dropdown-item>

            <template v-if="graphData.links.length">
              <gl-dropdown-divider />
              <gl-dropdown-item
                v-for="(link, index) in graphData.links"
                :key="index"
                :href="safeUrl(link.url)"
                class="text-break"
                >{{ link.title }}</gl-dropdown-item
              >
            </template>
            <template v-if="selectedDashboard && selectedDashboard.can_edit">
              <gl-dropdown-divider />
              <gl-dropdown-item ref="manageLinksItem" :href="selectedDashboard.project_blob_path">{{
                s__('Metrics|Manage chart links')
              }}</gl-dropdown-item>
            </template>
          </gl-dropdown>
        </div>
      </div>
    </div>

    <monitor-empty-chart v-if="!graphDataHasResult" />
    <component
      :is="basicChartComponent"
      v-else-if="basicChartComponent"
      :graph-data="graphData"
      v-bind="$attrs"
      v-on="$listeners"
    />
    <component
      :is="timeSeriesChartComponent"
      v-else
      ref="timeSeriesChart"
      :graph-data="graphData"
      :deployment-data="deploymentData"
      :annotations="annotations"
      :project-path="projectPath"
      :thresholds="getGraphAlertValues(graphData.metrics)"
      :group-id="groupId"
      v-bind="$attrs"
      v-on="$listeners"
      @datazoom="onDatazoom"
    />
  </div>
</template>
