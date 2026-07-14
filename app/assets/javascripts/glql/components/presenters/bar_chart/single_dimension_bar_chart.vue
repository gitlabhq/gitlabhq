<script>
import { GlBarChart } from '@gitlab/ui/src/charts';
import { stackedPresentationOptions } from '@gitlab/ui/src/utils/constants';
import { DISPLAY_TYPES } from '../../../constants';
import { buildBarSeriesData, tooltipContentFromParams } from '../../../utils/chart_data';
import {
  buildFormatterByLabel,
  buildSharedAxisFormatter,
  formatValueForLabel,
  yAxisTitleFor,
} from '../../../utils/value_format';
import FormattedTooltipContent from '../chart/formatted_tooltip_content.vue';

export default {
  name: 'SingleDimensionBarChart',
  components: { GlBarChart, FormattedTooltipContent },
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
    chartData() {
      return buildBarSeriesData(this.data.nodes, this.dimension, this.metrics);
    },
    presentation() {
      return this.stacked ? stackedPresentationOptions.stacked : stackedPresentationOptions.tiled;
    },
    formatterByLabel() {
      return buildFormatterByLabel(this.metrics);
    },
    sharedAxisFormatter() {
      return buildSharedAxisFormatter(this.metrics);
    },
    // GlBarChart flips the axes: the metric/value axis is x, and the
    // dimension/category axis is y. yAxisTitleFor derives a title from the
    // metrics regardless of which axis it ends up on.
    xAxisTitle() {
      return yAxisTitleFor(this.metrics);
    },
    chartOptions() {
      return this.sharedAxisFormatter
        ? { xAxis: { axisLabel: { formatter: this.sharedAxisFormatter } } }
        : {};
    },
  },
  methods: {
    formatValueByLabel(label, value) {
      return formatValueForLabel(this.formatterByLabel, label, value);
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
    :presentation="presentation"
    :x-axis-title="xAxisTitle"
    :y-axis-title="dimension.label"
  >
    <template #tooltip-content="{ params }">
      <formatted-tooltip-content
        :content="contentFromParams(params)"
        :format-value="formatValueByLabel"
      />
    </template>
  </gl-bar-chart>
</template>
