<script>
import {
  GlResizeObserverDirective,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlDropdown,
  GlDropdownItem,
  GlDropdownDivider,
  GlModal,
  GlModalDirective,
  GlSprintf,
  GlTooltip,
  GlTooltipDirective,
} from '@gitlab/ui';
import { mapState } from 'vuex';
import { convertToFixedRange } from '~/lib/utils/datetime_range';
import { isSafeURL } from '~/lib/utils/url_utility';
import { __, n__ } from '~/locale';
import TrackEventDirective from '~/vue_shared/directives/track_event';
import { panelTypes } from '../constants';

import { graphDataToCsv } from '../csv_export';
import { downloadCSVOptions, generateLinkToChartOptions } from '../utils';
import MonitorAnomalyChart from './charts/anomaly.vue';
import MonitorBarChart from './charts/bar.vue';
import MonitorColumnChart from './charts/column.vue';
import MonitorEmptyChart from './charts/empty_chart.vue';
import MonitorGaugeChart from './charts/gauge.vue';
import MonitorHeatmapChart from './charts/heatmap.vue';
import MonitorSingleStatChart from './charts/single_stat.vue';
import MonitorStackedColumnChart from './charts/stacked_column.vue';
import MonitorTimeSeriesChart from './charts/time_series.vue';

const events = {
  timeRangeZoom: 'timerangezoom',
  expand: 'expand',
};

export default {
  components: {
    MonitorEmptyChart,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlTooltip,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlModal,
    GlSprintf,
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
      timeRange(state) {
        return state[this.namespace].timeRange;
      },
      dashboardTimezone(state) {
        return state[this.namespace].dashboardTimezone;
      },
      metricsSavedToDb(state, getters) {
        return getters[`${this.namespace}/metricsSavedToDb`];
      },
      selectedDashboard(state, getters) {
        return getters[`${this.namespace}/selectedDashboard`];
      },
    }),
    fixedCurrentTimeRange() {
      // convertToFixedRange throws an error if the time range
      // is not properly set.
      try {
        return convertToFixedRange(this.timeRange);
      } catch {
        return {};
      }
    },
    title() {
      return this.graphData?.title || '';
    },
    graphDataHasResult() {
      const metrics = this.graphData?.metrics || [];
      return metrics.some(({ result }) => result?.length > 0);
    },
    graphDataIsLoading() {
      const metrics = this.graphData?.metrics || [];
      return metrics.some(({ loading }) => loading);
    },
    csvText() {
      if (this.graphData) {
        return graphDataToCsv(this.graphData);
      }
      return null;
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
      if (this.isPanelType(panelTypes.GAUGE_CHART)) {
        return MonitorGaugeChart;
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
     * data" and "datazoom".
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
      if (!this.graphDataHasResult) {
        return false;
      }
      // Only a few charts have a contextual menu, support
      // for more chart types planned at:
      // https://gitlab.com/groups/gitlab-org/-/epics/3573
      return (
        this.isPanelType(panelTypes.AREA_CHART) ||
        this.isPanelType(panelTypes.LINE_CHART) ||
        this.isPanelType(panelTypes.SINGLE_STAT) ||
        this.isPanelType(panelTypes.GAUGE_CHART)
      );
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
  },
  mounted() {
    this.refreshTitleTooltip();
  },
  methods: {
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
    onExpandFromKeyboardShortcut() {
      if (this.isContextualMenuShown) {
        this.onExpand();
      }
    },
    safeUrl(url) {
      return isSafeURL(url) ? url : '#';
    },
    downloadCsvFromKeyboardShortcut() {
      if (this.csvText && this.isContextualMenuShown) {
        this.$refs.downloadCsvLink.$el.firstChild.click();
      }
    },
    copyChartLinkFromKeyboardShotcut() {
      if (this.clipboardText && this.isContextualMenuShown) {
        this.$refs.copyChartLink.$el.firstChild.click();
      }
    },
  },
  panelTypes,
};
</script>
<template>
  <div v-gl-resize-observer="onResize" class="prometheus-graph">
    <div class="d-flex align-items-center">
      <slot name="top-left"></slot>
      <h5
        ref="graphTitle"
        class="prometheus-graph-title gl-font-lg font-weight-bold text-truncate gl-mr-3"
      >
        {{ title }}
      </h5>
      <gl-tooltip :target="() => $refs.graphTitle" :disabled="!showTitleTooltip">
        {{ title }}
      </gl-tooltip>
      <div class="flex-grow-1"></div>
      <div v-if="graphDataIsLoading" class="mx-1 mt-1">
        <gl-loading-icon size="sm" />
      </div>
      <div v-if="isContextualMenuShown" ref="contextualMenu">
        <div data-testid="dropdown-wrapper" class="d-flex align-items-center">
          <!--
            This component should be replaced with a variant developed
            as part of https://gitlab.com/gitlab-org/gitlab-ui/-/issues/936
            The variant will create a dropdown with an icon, no text and no caret
           -->
          <gl-dropdown
            v-gl-tooltip
            icon="ellipsis_v"
            :text="__('More actions')"
            :text-sr-only="true"
            toggle-class="gl-px-3!"
            no-caret
            right
            :title="__('More actions')"
          >
            <gl-dropdown-item v-if="expandBtnAvailable" ref="expandBtn" @click.prevent="onExpand">
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

            <template v-if="graphData.links && graphData.links.length">
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
      :timezone="dashboardTimezone"
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
      :group-id="groupId"
      :timezone="dashboardTimezone"
      :time-range="fixedCurrentTimeRange"
      v-bind="$attrs"
      v-on="$listeners"
      @datazoom="onDatazoom"
    />
  </div>
</template>
