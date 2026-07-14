<script>
import { GlBarChart } from '@gitlab/ui/src/charts';
import { DISPLAY_TYPES } from '../../../constants';
import { buildStackedByDimension, tooltipContentFromParams } from '../../../utils/chart_data';
import { formatterFor, axisFormatterFor, dimensionAxisTitleFor } from '../../../utils/value_format';
import FormattedTooltipContent from '../chart/formatted_tooltip_content.vue';

export default {
  name: 'TwoDimensionsBarChart',
  components: { GlBarChart, FormattedTooltipContent },
  props: {
    data: {
      required: true,
      type: Object,
    },
    primaryDimension: {
      required: true,
      type: Object,
    },
    secondaryDimension: {
      required: true,
      type: Object,
    },
    metric: {
      required: true,
      type: Object,
    },
  },
  computed: {
    chart() {
      return buildStackedByDimension({
        nodes: this.data.nodes,
        primaryDim: this.primaryDimension,
        secondaryDim: this.secondaryDimension,
        metric: this.metric,
      });
    },
    // GlBarChart has no `group-by` prop (unlike GlStackedColumnChart) and no
    // custom tooltip title logic of its own — it relies on the shared
    // ChartTooltip's default, which reads the category label out of each
    // point's own tuple. So, unlike columnChart's two-dimension case (which
    // can pass plain numbers plus a separate category list), each point here
    // must carry its own `[value, categoryLabel]` tuple, matching the
    // single-dimension bar chart's convention.
    chartData() {
      return Object.fromEntries(
        this.chart.bars.map(({ name, data }) => [
          name,
          data.map((value, i) => [value, this.chart.groups[i]]),
        ]),
      );
    },
    metricFormatter() {
      return formatterFor(this.metric?.key);
    },
    metricAxisFormatter() {
      return axisFormatterFor(this.metric?.key);
    },
    yAxisTitle() {
      return dimensionAxisTitleFor(this.primaryDimension, this.secondaryDimension);
    },
    chartOptions() {
      return { xAxis: { axisLabel: { formatter: this.metricAxisFormatter } } };
    },
  },
  methods: {
    formatTooltipValue(_label, value) {
      return this.metricFormatter(value);
    },
    contentFromParams(params) {
      return tooltipContentFromParams(params, DISPLAY_TYPES.BAR_CHART);
    },
  },
};
</script>

<template>
  <gl-bar-chart
    :data="chartData"
    :option="chartOptions"
    presentation="stacked"
    :x-axis-title="metric.label"
    :y-axis-title="yAxisTitle"
  >
    <template #tooltip-content="{ params }">
      <formatted-tooltip-content
        :content="contentFromParams(params)"
        :format-value="formatTooltipValue"
      />
    </template>
  </gl-bar-chart>
</template>
