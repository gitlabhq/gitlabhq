<script>
import { GlHeatmap } from '@gitlab/ui/dist/charts';
import dateformat from 'dateformat';
import PrometheusHeader from '../shared/prometheus_header.vue';
import ResizableChartContainer from '~/vue_shared/components/resizable_chart/resizable_chart_container.vue';
import { graphDataValidatorForValues } from '../../utils';

export default {
  components: {
    GlHeatmap,
    ResizableChartContainer,
    PrometheusHeader,
  },
  props: {
    graphData: {
      type: Object,
      required: true,
      validator: graphDataValidatorForValues.bind(null, false),
    },
    containerWidth: {
      type: Number,
      required: true,
    },
  },
  computed: {
    chartData() {
      return this.metrics.result.reduce(
        (acc, result, i) => [...acc, ...result.values.map((value, j) => [i, j, value[1]])],
        [],
      );
    },
    xAxisName() {
      return this.graphData.x_label || '';
    },
    yAxisName() {
      return this.graphData.y_label || '';
    },
    xAxisLabels() {
      return this.metrics.result.map(res => Object.values(res.metric)[0]);
    },
    yAxisLabels() {
      return this.result.values.map(val => {
        const [yLabel] = val;

        return dateformat(new Date(yLabel), 'HH:MM:ss');
      });
    },
    result() {
      return this.metrics.result[0];
    },
    metrics() {
      return this.graphData.metrics[0];
    },
  },
};
</script>
<template>
  <div class="prometheus-graph col-12 col-lg-6">
    <prometheus-header :graph-title="graphData.title" />
    <resizable-chart-container>
      <gl-heatmap
        ref="heatmapChart"
        v-bind="$attrs"
        :data-series="chartData"
        :x-axis-name="xAxisName"
        :y-axis-name="yAxisName"
        :x-axis-labels="xAxisLabels"
        :y-axis-labels="yAxisLabels"
        :width="containerWidth"
      />
    </resizable-chart-container>
  </div>
</template>
