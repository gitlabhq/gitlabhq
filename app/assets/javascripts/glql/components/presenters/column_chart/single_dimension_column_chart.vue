<script>
import { GlColumnChart, GlStackedColumnChart } from '@gitlab/ui/src/charts';
import { stackedPresentationOptions } from '@gitlab/ui/src/utils/constants';
import {
  baseFieldKeyOf,
  buildSeries,
  buildStackedByMetric,
  dimensionLabelFormatter,
  labelWithParameter,
  tooltipContentFromParams,
  tooltipTitleFromParams,
} from '../../../utils/chart_data';
import {
  axisFormatterFor,
  buildFormatterByLabel,
  buildSharedAxisFormatter,
  formatValueForLabel,
  yAxisTitleFor,
} from '../../../utils/value_format';
import FormattedTooltipContent from '../chart/formatted_tooltip_content.vue';

export default {
  name: 'SingleDimensionColumnChart',
  components: { GlColumnChart, GlStackedColumnChart, FormattedTooltipContent },
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
    formatterByLabel() {
      return buildFormatterByLabel(this.metrics);
    },
    sharedAxisFormatter() {
      return buildSharedAxisFormatter(this.metrics);
    },
    dimensionLabel() {
      return labelWithParameter(this.dimension);
    },
    categoryFormatter() {
      return dimensionLabelFormatter(this.data.nodes, this.dimension);
    },
    chartOptions() {
      const xAxis = { axisLabel: { formatter: this.categoryFormatter } };
      // Dual-axis: per-metric formatter on each axis. ECharts deep-merges yAxis
      // by index when given an array.
      if (this.metrics.length === 2 && !this.useSingleAxisChart) {
        return {
          xAxis,
          yAxis: [
            { axisLabel: { formatter: axisFormatterFor(baseFieldKeyOf(this.metrics[0])) } },
            { axisLabel: { formatter: axisFormatterFor(baseFieldKeyOf(this.metrics[1])) } },
          ],
        };
      }
      // Stacked single-axis: apply the formatter only when all metrics share a
      // unit. GlStackedColumnChart declares yAxis as an array, so we have to
      // pass an array for the merge to apply.
      if (this.useSingleAxisChart) {
        return this.sharedAxisFormatter
          ? { xAxis, yAxis: [{ axisLabel: { formatter: this.sharedAxisFormatter } }] }
          : { xAxis };
      }
      return {
        xAxis,
        yAxis: { axisLabel: { formatter: axisFormatterFor(baseFieldKeyOf(this.metrics[0])) } },
      };
    },
    presentation() {
      return this.stacked ? stackedPresentationOptions.stacked : stackedPresentationOptions.tiled;
    },
    yAxisTitle() {
      if (this.useSingleAxisChart) return yAxisTitleFor(this.metrics);
      return labelWithParameter(this.metrics[0]) ?? '';
    },
    secondaryDataTitle() {
      return labelWithParameter(this.metrics[1]);
    },
  },
  methods: {
    formatValueByLabel(label, value) {
      return formatValueForLabel(this.formatterByLabel, label, value);
    },
    tooltipTitle(params) {
      return tooltipTitleFromParams(params, {
        formatLabel: this.categoryFormatter,
        axisName: this.dimensionLabel,
      });
    },
    contentFromParams: tooltipContentFromParams,
  },
};
</script>

<template>
  <gl-stacked-column-chart
    v-if="useSingleAxisChart"
    x-axis-type="category"
    :x-axis-title="dimensionLabel"
    :y-axis-title="yAxisTitle"
    :group-by="multiMetricData.groups"
    :bars="multiMetricData.bars"
    :option="chartOptions"
    :presentation="presentation"
    :include-legend-avg-max="false"
  >
    <template #tooltip-title="{ params }">{{ tooltipTitle(params) }}</template>
    <template #tooltip-content="{ params }">
      <formatted-tooltip-content
        :content="contentFromParams(params)"
        :format-value="formatValueByLabel"
      />
    </template>
  </gl-stacked-column-chart>
  <gl-column-chart
    v-else
    :bars="primaryBars"
    :option="chartOptions"
    x-axis-type="category"
    :x-axis-title="dimensionLabel"
    :y-axis-title="yAxisTitle"
    :secondary-data="secondaryBars"
    :secondary-data-title="secondaryDataTitle"
  >
    <template #tooltip-title="{ params }">{{ tooltipTitle(params) }}</template>
    <template #tooltip-content="{ params }">
      <formatted-tooltip-content
        :content="contentFromParams(params)"
        :format-value="formatValueByLabel"
      />
    </template>
  </gl-column-chart>
</template>
