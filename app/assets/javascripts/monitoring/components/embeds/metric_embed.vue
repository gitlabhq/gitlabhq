<script>
import { mapState, mapActions } from 'vuex';
import PanelType from 'ee_else_ce/monitoring/components/panel_type.vue';
import { convertToFixedRange } from '~/lib/utils/datetime_range';
import { defaultTimeRange } from '~/vue_shared/constants';
import { timeRangeFromUrl, removeTimeRangeParams } from '../../utils';
import { sidebarAnimationDuration } from '../../constants';

let sidebarMutationObserver;

export default {
  components: {
    PanelType,
  },
  props: {
    containerClass: {
      type: String,
      required: false,
      default: 'col-lg-12',
    },
    dashboardUrl: {
      type: String,
      required: true,
    },
    namespace: {
      type: String,
      required: false,
      default: 'monitoringDashboard',
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
    ...mapState({
      dashboard(state) {
        return state[this.namespace].dashboard;
      },
      metricsWithData(state, getters) {
        return getters[`${this.namespace}/metricsWithData`]();
      },
    }),
    charts() {
      if (!this.dashboard || !this.dashboard.panelGroups) {
        return [];
      }
      return this.dashboard.panelGroups.reduce(
        (acc, currentGroup) => acc.concat(currentGroup.panels.filter(this.chartHasData)),
        [],
      );
    },
    isSingleChart() {
      return this.charts.length === 1;
    },
    embedClass() {
      return this.isSingleChart ? this.containerClass : 'col-lg-12';
    },
    panelClass() {
      return this.isSingleChart ? 'col-lg-12' : 'col-lg-6';
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
    // Use function args to support dynamic namespaces in mapXXX helpers. Pattern described
    // in https://github.com/vuejs/vuex/issues/863#issuecomment-329510765
    ...mapActions({
      setTimeRange(dispatch, payload) {
        return dispatch(`${this.namespace}/setTimeRange`, payload);
      },
      fetchDashboard(dispatch, payload) {
        return dispatch(`${this.namespace}/fetchDashboard`, payload);
      },
      setEndpoints(dispatch, payload) {
        return dispatch(`${this.namespace}/setEndpoints`, payload);
      },
      setFeatureFlags(dispatch, payload) {
        return dispatch(`${this.namespace}/setFeatureFlags`, payload);
      },
      setShowErrorBanner(dispatch, payload) {
        return dispatch(`${this.namespace}/setShowErrorBanner`, payload);
      },
    }),
    chartHasData(chart) {
      return chart.metrics.some(metric => this.metricsWithData.includes(metric.metricId));
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
  <div class="metrics-embed p-0 d-flex flex-wrap" :class="embedClass">
    <panel-type
      v-for="(graphData, graphIndex) in charts"
      :key="`panel-type-${graphIndex}`"
      :class="panelClass"
      :graph-data="graphData"
      :group-id="dashboardUrl"
      :namespace="namespace"
    />
  </div>
</template>
