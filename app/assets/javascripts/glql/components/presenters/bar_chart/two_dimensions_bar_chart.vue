<script>
import { GlBarChart } from '@gitlab/ui/src/charts';
import { DISPLAY_TYPES } from '../../../constants';
import {
  buildStackedByDimension,
  dimensionLabelFormatter,
  tooltipContentFromParams,
  tooltipTitleFromParams,
  baseFieldKeyOf,
  labelWithParameter,
} from '../../../utils/chart_data';
import { formatterFor, axisFormatterFor, dimensionAxisTitleFor } from '../../../utils/value_format';
import FormattedTooltipContent from '../chart/formatted_tooltip_content.vue';
import { barCategoryAxisOptions } from './bar_chart_options';

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
      return formatterFor(baseFieldKeyOf(this.metric));
    },
    metricAxisFormatter() {
      return axisFormatterFor(baseFieldKeyOf(this.metric));
    },
    yAxisTitle() {
      return dimensionAxisTitleFor(this.primaryDimension, this.secondaryDimension);
    },
    categoryFormatter() {
      return dimensionLabelFormatter(this.data.nodes, this.primaryDimension);
    },
    xAxisTitle() {
      return labelWithParameter(this.metric);
    },
    chartOptions() {
      return {
        ...barCategoryAxisOptions(this.chart.groups.map(this.categoryFormatter), {
          formatter: this.categoryFormatter,
        }),
        xAxis: { axisLabel: { formatter: this.metricAxisFormatter } },
      };
    },
  },
  methods: {
    formatTooltipValue(_label, value) {
      return this.metricFormatter(value);
    },
    contentFromParams(params) {
      return tooltipContentFromParams(params, DISPLAY_TYPES.BAR_CHART);
    },
    tooltipTitle(params) {
      return tooltipTitleFromParams(params, {
        formatLabel: this.categoryFormatter,
        axisName: this.yAxisTitle,
        displayType: DISPLAY_TYPES.BAR_CHART,
      });
    },
  },
};
</script>

<template>
  <gl-bar-chart
    :data="chartData"
    :option="chartOptions"
    presentation="stacked"
    :x-axis-title="xAxisTitle"
    :y-axis-title="yAxisTitle"
  >
    <template #tooltip-title="{ params }">{{ tooltipTitle(params) }}</template>
    <template #tooltip-content="{ params }">
      <formatted-tooltip-content
        :content="contentFromParams(params)"
        :format-value="formatTooltipValue"
      />
    </template>
  </gl-bar-chart>
</template>
