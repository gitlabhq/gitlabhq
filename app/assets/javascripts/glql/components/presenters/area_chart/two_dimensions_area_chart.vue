<script>
import { GlAreaChart } from '@gitlab/ui/src/charts';
import {
  baseFieldKeyOf,
  buildStackedByDimension,
  labelWithParameter,
  tooltipContentFromParams,
} from '../../../utils/chart_data';
import { formatterFor, axisFormatterFor, dimensionAxisTitleFor } from '../../../utils/value_format';
import FormattedTooltipContent from '../chart/formatted_tooltip_content.vue';

const STACK_ID = 'secondary-dimension';

// Overlapping areas for a folded-in second dimension would be unreadable, so
// two-dimensional area charts are always stacked (as are the column and bar
// equivalents).
export default {
  name: 'TwoDimensionsAreaChart',
  components: { GlAreaChart, FormattedTooltipContent },
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
    chartData() {
      const { groups, bars } = buildStackedByDimension({
        nodes: this.data.nodes,
        primaryDim: this.primaryDimension,
        secondaryDim: this.secondaryDimension,
        metric: this.metric,
      });
      return bars.map(({ name, data }) => ({
        name,
        stack: STACK_ID,
        data: data.map((value, index) => [groups[index], value]),
      }));
    },
    metricFormatter() {
      return formatterFor(baseFieldKeyOf(this.metric));
    },
    metricAxisFormatter() {
      return axisFormatterFor(baseFieldKeyOf(this.metric));
    },
    yAxisTitle() {
      return labelWithParameter(this.metric);
    },
    chartOptions() {
      return {
        xAxis: {
          name: dimensionAxisTitleFor(this.primaryDimension, this.secondaryDimension),
          type: 'category',
        },
        yAxis: {
          name: this.yAxisTitle,
          axisLabel: { formatter: this.metricAxisFormatter },
        },
      };
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
  <gl-area-chart :data="chartData" :option="chartOptions" :include-legend-avg-max="false">
    <template #tooltip-content="{ params }">
      <formatted-tooltip-content
        :content="contentFromParams(params)"
        :format-value="formatTooltipValue"
      />
    </template>
  </gl-area-chart>
</template>
