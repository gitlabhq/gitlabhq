<script>
import { GlLineChart, GlChartSeriesLabel } from '@gitlab/ui/src/charts';
import { merge, omit } from 'lodash-es';

import {
  formatChartTooltipTitle,
  formatVisualizationTooltipTitle,
  formatVisualizationValue,
  humanizeChartTooltipValue,
  removeNullSeries,
} from './utils';

export default {
  name: 'LineChart',
  components: {
    GlLineChart,
    GlChartSeriesLabel,
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
    includeLegendAvgMax() {
      return Boolean(this.options.includeLegendAvgMax);
    },
    fullOptions() {
      const unit = this.options.yAxis?.valueUnit;
      const base = {
        yAxis: {
          min: 0,
          ...(unit && {
            axisLabel: {
              formatter: (value) => humanizeChartTooltipValue({ unit, value }),
            },
          }),
        },
      };

      // Exclude `tooltip` to prevent ECharts from rendering default tooltip, and
      // `yAxis.valueUnit` since it is our own concept, not an ECharts option.
      return merge(base, omit(this.options, ['tooltip', 'yAxis.valueUnit']));
    },
  },
  methods: {
    formatTooltipTitle(title, params) {
      const { chartTooltip: { titleFormatter: formatter } = {} } = this.options;

      if (formatter) {
        const xAxisValue = params?.seriesData?.at(0)?.value?.at(0);

        return formatChartTooltipTitle({ title, value: xAxisValue, formatter });
      }

      return formatVisualizationTooltipTitle(title, params);
    },
    formatTooltipValue(tooltipData) {
      const [, value] = tooltipData;
      const { chartTooltip: { valueUnit: unit } = {} } = this.options;

      if (unit) {
        return humanizeChartTooltipValue({ unit, value });
      }

      return formatVisualizationValue(value);
    },
    tooltipData(params) {
      if (!params) return [];

      return removeNullSeries(params.seriesData);
    },
  },
};
</script>

<template>
  <gl-line-chart
    :data="data"
    :option="fullOptions"
    :include-legend-avg-max="includeLegendAvgMax"
    height="auto"
    responsive
    class="gl-overflow-hidden"
    data-testid="dashboard-visualization-line-chart"
  >
    <template #tooltip-title="{ title, params }"> {{ formatTooltipTitle(title, params) }}</template>
    <template #tooltip-content="{ params }">
      <div
        v-for="{ seriesId, seriesName, color, value } in tooltipData(params)"
        :key="seriesId"
        data-testid="chart-tooltip-item"
        class="gl-flex gl-min-w-30 gl-justify-between gl-leading-24"
      >
        <gl-chart-series-label class="gl-mr-7 gl-text-sm" :color="color">{{
          seriesName
        }}</gl-chart-series-label>
        <span class="gl-font-bold" data-testid="chart-tooltip-value">{{
          formatTooltipValue(value)
        }}</span>
      </div>
    </template>
  </gl-line-chart>
</template>
