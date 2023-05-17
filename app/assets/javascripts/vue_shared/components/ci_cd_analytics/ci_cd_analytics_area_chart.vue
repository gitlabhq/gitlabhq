<script>
import { v4 as uuidv4 } from 'uuid';
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
  data: () => ({
    chartKey: uuidv4(),
  }),
  watch: {
    chartData() {
      // Re-render area chart when the data changes
      this.chartKey = uuidv4();
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
      :key="chartKey"
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
