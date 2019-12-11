<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { getParameterValues, removeParams } from '~/lib/utils/url_utility';
import PanelType from 'ee_else_ce/monitoring/components/panel_type.vue';
import GraphGroup from './graph_group.vue';
import { sidebarAnimationDuration } from '../constants';
import { getTimeDiff } from '../utils';

let sidebarMutationObserver;

export default {
  components: {
    GraphGroup,
    PanelType,
  },
  props: {
    dashboardUrl: {
      type: String,
      required: true,
    },
  },
  data() {
    const defaultRange = getTimeDiff();
    const start = getParameterValues('start', this.dashboardUrl)[0] || defaultRange.start;
    const end = getParameterValues('end', this.dashboardUrl)[0] || defaultRange.end;

    const params = {
      start,
      end,
    };

    return {
      params,
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
    this.fetchMetricsData(this.params);
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
      'fetchMetricsData',
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
        dashboardEndpoint: removeParams(['start', 'end'], this.dashboardUrl),
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
        clipboard-text=""
        :graph-data="graphData"
        :group-id="dashboardUrl"
      />
    </div>
  </div>
</template>
