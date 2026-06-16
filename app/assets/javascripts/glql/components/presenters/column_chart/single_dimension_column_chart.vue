<script>
import { GlColumnChart, GlStackedColumnChart } from '@gitlab/ui/src/charts';
import { stackedPresentationOptions } from '@gitlab/ui/src/utils/constants';
import {
  buildSeries,
  buildStackedByMetric,
  tooltipContentFromParams,
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
    chartOptions() {
      // Dual-axis: per-metric formatter on each axis. ECharts deep-merges yAxis
      // by index when given an array.
      if (this.metrics.length === 2 && !this.useSingleAxisChart) {
        return {
          yAxis: [
            { axisLabel: { formatter: axisFormatterFor(this.metrics[0]?.key) } },
            { axisLabel: { formatter: axisFormatterFor(this.metrics[1]?.key) } },
          ],
        };
      }
      // Stacked single-axis: apply the formatter only when all metrics share a
      // unit. GlStackedColumnChart declares yAxis as an array, so we have to
      // pass an array for the merge to apply.
      if (this.useSingleAxisChart) {
        return this.sharedAxisFormatter
          ? { yAxis: [{ axisLabel: { formatter: this.sharedAxisFormatter } }] }
          : {};
      }
      return { yAxis: { axisLabel: { formatter: axisFormatterFor(this.metrics[0]?.key) } } };
    },
    presentation() {
      return this.stacked ? stackedPresentationOptions.stacked : stackedPresentationOptions.tiled;
    },
    yAxisTitle() {
      if (this.useSingleAxisChart) return yAxisTitleFor(this.metrics);
      return this.metrics[0]?.label ?? '';
    },
  },
  methods: {
    formatValueByLabel(label, value) {
      return formatValueForLabel(this.formatterByLabel, label, value);
    },
    contentFromParams: tooltipContentFromParams,
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
    :option="chartOptions"
    :presentation="presentation"
    :include-legend-avg-max="false"
  >
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
    :x-axis-title="dimension.label"
    :y-axis-title="yAxisTitle"
    :secondary-data="secondaryBars"
    :secondary-data-title="metrics[1]?.label"
  >
    <template #tooltip-content="{ params }">
      <formatted-tooltip-content
        :content="contentFromParams(params)"
        :format-value="formatValueByLabel"
      />
    </template>
  </gl-column-chart>
</template>
