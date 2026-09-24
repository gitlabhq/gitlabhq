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
import { barCategoryAxisOptions, barChartHeightFor } from './bar_chart_options';

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
    showAxisTitles: {
      required: false,
      type: Boolean,
      default: true,
    },
  },
  computed: {
    chart() {
      return buildStackedByDimension({
        nodes: this.data.nodes,
        primaryDim: this.primaryDimension,
        secondaryDim: this.secondaryDimension,
        metric: this.metric,
        missingValue: null,
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
    // The tooltip keeps naming the dimensions even when the axis titles are
    // hidden, since it is the only place the grouping is spelled out then.
    dimensionAxisTitle() {
      return dimensionAxisTitleFor(this.primaryDimension, this.secondaryDimension);
    },
    yAxisTitle() {
      return this.showAxisTitles ? this.dimensionAxisTitle : '';
    },
    categoryFormatter() {
      return dimensionLabelFormatter(this.data.nodes, this.primaryDimension);
    },
    xAxisTitle() {
      return this.showAxisTitles ? labelWithParameter(this.metric) : '';
    },
    chartHeight() {
      return barChartHeightFor(this.chart.groups.length, { axisTitle: this.showAxisTitles });
    },
    chartOptions() {
      return {
        ...barCategoryAxisOptions(this.chart.groups.map(this.categoryFormatter), {
          formatter: this.categoryFormatter,
          axisTitle: this.showAxisTitles,
        }),
        xAxis: { axisLabel: { formatter: this.metricAxisFormatter } },
      };
    },
  },
  methods: {
    formatTooltipValue(_label, value) {
      return this.metricFormatter(value);
    },
    // Drop the padded pairs before the helper turns their null into 0.
    contentFromParams(params) {
      const seriesData = params?.seriesData?.filter(({ value }) => value?.[0] != null);
      return tooltipContentFromParams({ ...params, seriesData }, DISPLAY_TYPES.BAR_CHART);
    },
    tooltipTitle(params) {
      return tooltipTitleFromParams(params, {
        formatLabel: this.categoryFormatter,
        axisName: this.dimensionAxisTitle,
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
    :height="chartHeight"
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
