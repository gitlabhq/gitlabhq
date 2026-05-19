<script>
import { GlColumnChart, GlStackedColumnChart } from '@gitlab/ui/src/charts';
import { stackedPresentationOptions } from '@gitlab/ui/src/utils/constants';
import { buildSeries, buildStackedByMetric } from '../../../utils/chart_data';

export default {
  name: 'SingleDimensionColumnChart',
  components: { GlColumnChart, GlStackedColumnChart },
  props: {
    data: {
      required: true,
      type: Object,
    },
    dimension: {
      required: true,
      type: Object,
    },
    metrics: {
      required: true,
      type: Array,
    },
    stacked: {
      required: false,
      type: Boolean,
      default: false,
    },
  },
  computed: {
    // GlColumnChart renders 1 metric (single series) or 2 metrics on a dual y-axis.
    // 3+ metrics, or stacking, go through GlStackedColumnChart on a single axis.
    useSingleAxisChart() {
      return this.stacked || this.metrics.length > 2;
    },
    primaryBars() {
      return buildSeries(this.data.nodes, this.dimension, this.metrics[0]);
    },
    secondaryBars() {
      return buildSeries(this.data.nodes, this.dimension, this.metrics[1]);
    },
    multiMetricData() {
      return buildStackedByMetric(this.data.nodes, this.dimension, this.metrics);
    },
    chartOptions() {
      return { yAxis: { axisLabel: { formatter: '{value}' } } };
    },
    presentation() {
      return this.stacked ? stackedPresentationOptions.stacked : stackedPresentationOptions.tiled;
    },
    yAxisTitle() {
      if (this.useSingleAxisChart) return '';
      return this.metrics[0]?.label ?? '';
    },
  },
};
</script>

<template>
  <gl-stacked-column-chart
    v-if="useSingleAxisChart"
    x-axis-type="category"
    :x-axis-title="dimension.label"
    :y-axis-title="yAxisTitle"
    :group-by="multiMetricData.groups"
    :bars="multiMetricData.bars"
    :presentation="presentation"
    :include-legend-avg-max="false"
  />
  <gl-column-chart
    v-else
    :bars="primaryBars"
    :option="chartOptions"
    x-axis-type="category"
    :x-axis-title="dimension.label"
    :y-axis-title="yAxisTitle"
    :secondary-data="secondaryBars"
    :secondary-data-title="metrics[1]?.label"
  />
</template>
