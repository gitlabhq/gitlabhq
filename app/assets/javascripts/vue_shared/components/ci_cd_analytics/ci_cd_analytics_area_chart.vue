<script>
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { CHART_CONTAINER_HEIGHT } from './constants';

export default {
  name: 'CiCdAnalyticsAreaChart',
  components: {
    GlAreaChart,
  },
  props: {
    chartData: {
      type: Array,
      required: true,
    },
    areaChartOptions: {
      type: Object,
      required: true,
    },
  },
  chartContainerHeight: CHART_CONTAINER_HEIGHT,
};
</script>
<template>
  <div class="gl-mt-3">
    <p>
      <slot></slot>
    </p>
    <gl-area-chart
      v-bind="$attrs"
      responsive
      width="auto"
      :height="$options.chartContainerHeight"
      :data="chartData"
      :include-legend-avg-max="false"
      :option="areaChartOptions"
    >
      <template #tooltip-title>
        <slot name="tooltip-title"></slot>
      </template>
      <template #tooltip-content>
        <slot name="tooltip-content"></slot>
      </template>
    </gl-area-chart>
  </div>
</template>
