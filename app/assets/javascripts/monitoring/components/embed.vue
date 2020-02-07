<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import PanelType from 'ee_else_ce/monitoring/components/panel_type.vue';
import { convertToFixedRange } from '~/lib/utils/datetime_range';
import { timeRangeFromUrl, removeTimeRangeParams } from '../utils';
import { sidebarAnimationDuration, defaultTimeRange } from '../constants';

let sidebarMutationObserver;

export default {
  components: {
    PanelType,
  },
  props: {
    dashboardUrl: {
      type: String,
      required: true,
    },
  },
  data() {
    const timeRange = timeRangeFromUrl(this.dashboardUrl) || defaultTimeRange;
    return {
      timeRange: convertToFixedRange(timeRange),
      elWidth: 0,
    };
  },
  computed: {
    ...mapState('monitoringDashboard', ['dashboard']),
    ...mapGetters('monitoringDashboard', ['metricsWithData']),
    charts() {
      if (!this.dashboard || !this.dashboard.panel_groups) {
        return [];
      }
      const groupWithMetrics = this.dashboard.panel_groups.find(group =>
        group.panels.find(chart => this.chartHasData(chart)),
      ) || { panels: [] };

      return groupWithMetrics.panels.filter(chart => this.chartHasData(chart));
    },
    isSingleChart() {
      return this.charts.length === 1;
    },
  },
  mounted() {
    this.setInitialState();
    this.setTimeRange(this.timeRange);
    this.fetchDashboard();

    sidebarMutationObserver = new MutationObserver(this.onSidebarMutation);
    sidebarMutationObserver.observe(document.querySelector('.layout-page'), {
      attributes: true,
      childList: false,
      subtree: false,
    });
  },
  beforeDestroy() {
    if (sidebarMutationObserver) {
      sidebarMutationObserver.disconnect();
    }
  },
  methods: {
    ...mapActions('monitoringDashboard', [
      'setTimeRange',
      'fetchDashboard',
      'setEndpoints',
      'setFeatureFlags',
      'setShowErrorBanner',
    ]),
    chartHasData(chart) {
      return chart.metrics.some(metric => this.metricsWithData().includes(metric.metric_id));
    },
    onSidebarMutation() {
      setTimeout(() => {
        this.elWidth = this.$el.clientWidth;
      }, sidebarAnimationDuration);
    },
    setInitialState() {
      this.setEndpoints({
        dashboardEndpoint: removeTimeRangeParams(this.dashboardUrl),
      });
      this.setShowErrorBanner(false);
    },
  },
};
</script>
<template>
  <div class="metrics-embed" :class="{ 'd-inline-flex col-lg-6 p-0': isSingleChart }">
    <div v-if="charts.length" class="row w-100 m-n2 pb-4">
      <panel-type
        v-for="(graphData, graphIndex) in charts"
        :key="`panel-type-${graphIndex}`"
        class="w-100"
        :graph-data="graphData"
        :group-id="dashboardUrl"
      />
    </div>
  </div>
</template>
