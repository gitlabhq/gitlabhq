<script>
import { GlAreaChart } from '@gitlab/ui/src/charts';
import { merge, omit } from 'lodash-es';
import { AREA_CHART_SERIES_OPTIONS } from '~/analytics/shared/constants';
import { formatChartTooltipTitle, humanizeChartTooltipValue } from './utils';

export default {
  name: 'AreaChart',
  components: {
    GlAreaChart,
  },
  props: {
    data: {
      type: Array,
      required: false,
      default: () => [],
    },
    options: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    fullOptions() {
      const defaultChartOptions = {
        xAxis: {
          type: 'category',
        },
        yAxis: {
          type: 'value',
        },
      };

      // Exclude `tooltip` to prevent ECharts from rendering default tooltip
      return merge({}, defaultChartOptions, omit(this.options, 'tooltip'));
    },
    chartData() {
      return this.data.map((seriesData) => ({
        ...seriesData,
        ...AREA_CHART_SERIES_OPTIONS,
      }));
    },
    includeLegendAvgMax() {
      return this.options.includeLegendAvgMax ?? true;
    },
  },
  methods: {
    formatTooltipTitle(title, params) {
      const { chartTooltip: { titleFormatter: formatter } = {} } = this.options;
      const xAxisValue = params?.seriesData?.at(0)?.value?.at(0);

      return formatChartTooltipTitle({ title, value: xAxisValue, formatter });
    },
    formatTooltipValue(value) {
      const { chartTooltip: { valueUnit } = {} } = this.options;

      return humanizeChartTooltipValue({ unit: valueUnit, value });
    },
  },
};
</script>

<template>
  <gl-area-chart
    :data="chartData"
    :option="fullOptions"
    :include-legend-avg-max="includeLegendAvgMax"
    height="auto"
    responsive
    data-testid="dashboard-visualization-area-chart"
  >
    <template #tooltip-title="{ title, params }"
      ><span data-testid="chart-tooltip-title">{{
        formatTooltipTitle(title, params)
      }}</span></template
    >
    <template #tooltip-value="{ value }"
      ><span data-testid="chart-tooltip-value">{{ formatTooltipValue(value) }}</span></template
    >
  </gl-area-chart>
</template>
