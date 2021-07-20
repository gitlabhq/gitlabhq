<script>
import { GlSegmentedControl } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import CiCdAnalyticsAreaChart from './ci_cd_analytics_area_chart.vue';

export default {
  components: {
    GlSegmentedControl,
    CiCdAnalyticsAreaChart,
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
  },
  data() {
    return {
      selectedChart: 0,
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
};
</script>
<template>
  <div>
    <gl-segmented-control v-model="selectedChart" :options="chartRanges" class="gl-mb-4" />
    <ci-cd-analytics-area-chart
      v-if="chart"
      v-bind="$attrs"
      :chart-data="chart.data"
      :area-chart-options="chartOptions"
    >
      {{ dateRange }}
      <template #tooltip-title>
        <slot name="tooltip-title"></slot>
      </template>
      <template #tooltip-content>
        <slot name="tooltip-content"></slot>
      </template>
    </ci-cd-analytics-area-chart>
  </div>
</template>
