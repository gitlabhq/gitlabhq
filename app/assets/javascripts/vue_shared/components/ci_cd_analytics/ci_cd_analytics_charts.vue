<script>
import { GlSegmentedControl } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import CiCdAnalyticsAreaChart from './ci_cd_analytics_area_chart.vue';
import { DEFAULT_SELECTED_CHART } from './constants';

export default {
  components: {
    CiCdAnalyticsAreaChart,
    GlSegmentedControl,
  },
  props: {
    charts: {
      required: true,
      type: Array,
    },
    chartOptions: {
      required: true,
      type: Object,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    formatTooltipText: {
      type: Function,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      selectedChart: DEFAULT_SELECTED_CHART,
    };
  },
  computed: {
    chartRanges() {
      return this.charts.map(({ title }, index) => ({ text: title, value: index }));
    },
    chart() {
      return this.charts[this.selectedChart];
    },
    dateRange() {
      return sprintf(s__('CiCdAnalytics|Date range: %{range}'), { range: this.chart.range });
    },
  },
  methods: {
    onInput(selectedChart) {
      this.selectedChart = selectedChart;
      this.$emit('select-chart', selectedChart);
    },
  },
};
</script>
<template>
  <div>
    <div class="gl-flex gl-flex-wrap gl-gap-5">
      <gl-segmented-control :options="chartRanges" :value="selectedChart" @input="onInput" />
      <slot name="extend-button-group"></slot>
    </div>
    <ci-cd-analytics-area-chart
      v-if="chart"
      v-bind="$attrs"
      :chart-data="chart.data"
      :area-chart-options="chartOptions"
      :loading="loading"
      :format-tooltip-text="formatTooltipText"
    >
      <slot name="alerts"></slot>
      <p>{{ dateRange }}</p>
      <slot name="metrics" :selected-chart="selectedChart"></slot>
      <template #tooltip-title>
        <slot name="tooltip-title"></slot>
      </template>
      <template #tooltip-content>
        <slot name="tooltip-content"></slot>
      </template>
    </ci-cd-analytics-area-chart>
  </div>
</template>
