<script>
import { GlStackedColumnChart } from '@gitlab/ui/src/charts';
import {
  buildStackedByDimension,
  tooltipContentFromParams,
  baseFieldKeyOf,
  labelWithParameter,
} from '../../../utils/chart_data';
import { formatterFor, axisFormatterFor, dimensionAxisTitleFor } from '../../../utils/value_format';
import FormattedTooltipContent from '../chart/formatted_tooltip_content.vue';

export default {
  name: 'TwoDimensionsColumnChart',
  components: { GlStackedColumnChart, FormattedTooltipContent },
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
    metricFormatter() {
      return formatterFor(baseFieldKeyOf(this.metric));
    },
    metricAxisFormatter() {
      return axisFormatterFor(baseFieldKeyOf(this.metric));
    },
    xAxisTitle() {
      return dimensionAxisTitleFor(this.primaryDimension, this.secondaryDimension);
    },
    yAxisTitle() {
      return labelWithParameter(this.metric);
    },
    chartOptions() {
      // GlStackedColumnChart declares yAxis as an array; pass an array so the
      // formatter merges in. Axis uses the compact variant for counts; tooltip
      // keeps full-digit formatting via metricFormatter below.
      return { yAxis: [{ axisLabel: { formatter: this.metricAxisFormatter } }] };
    },
  },
  methods: {
    formatTooltipValue(_label, value) {
      return this.metricFormatter(value);
    },
    contentFromParams: tooltipContentFromParams,
  },
};
</script>

<template>
  <gl-stacked-column-chart
    x-axis-type="category"
    :x-axis-title="xAxisTitle"
    :y-axis-title="yAxisTitle"
    :group-by="chart.groups"
    :bars="chart.bars"
    :option="chartOptions"
    presentation="stacked"
    :include-legend-avg-max="false"
  >
    <template #tooltip-content="{ params }">
      <formatted-tooltip-content
        :content="contentFromParams(params)"
        :format-value="formatTooltipValue"
      />
    </template>
  </gl-stacked-column-chart>
</template>
