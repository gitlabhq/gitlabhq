<script>
import { GlHeatmap } from '@gitlab/ui/dist/charts';
import { formatDate, timezones, formats } from '../../format_date';
import { graphDataValidatorForValues } from '../../utils';

export default {
  components: {
    GlHeatmap,
  },
  props: {
    graphData: {
      type: Object,
      required: true,
      validator: graphDataValidatorForValues.bind(null, false),
    },
    timezone: {
      type: String,
      required: false,
      default: timezones.LOCAL,
    },
  },
  data() {
    return {
      width: 0,
    };
  },
  computed: {
    chartData() {
      return this.metrics.result.reduce(
        (acc, result, i) => [...acc, ...result.values.map((value, j) => [i, j, value[1]])],
        [],
      );
    },
    xAxisName() {
      return this.graphData.xLabel || '';
    },
    yAxisName() {
      return this.graphData.y_label || '';
    },
    xAxisLabels() {
      return this.metrics.result.map((res) => Object.values(res.metric)[0]);
    },
    yAxisLabels() {
      return this.result.values.map((val) => {
        const [yLabel] = val;

        return formatDate(new Date(yLabel), {
          format: formats.shortTime,
          timezone: this.timezone,
        });
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
  <gl-heatmap
    ref="heatmapChart"
    v-bind="$attrs"
    :responsive="true"
    :data-series="chartData"
    :x-axis-name="xAxisName"
    :y-axis-name="yAxisName"
    :x-axis-labels="xAxisLabels"
    :y-axis-labels="yAxisLabels"
    :width="width"
  />
</template>
