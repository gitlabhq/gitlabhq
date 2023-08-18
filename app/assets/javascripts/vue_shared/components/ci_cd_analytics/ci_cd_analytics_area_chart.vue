<script>
import { v4 as uuidv4 } from 'uuid';
import { GlSkeletonLoader } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { CHART_CONTAINER_HEIGHT } from './constants';

export default {
  name: 'CiCdAnalyticsAreaChart',
  components: {
    GlAreaChart,
    GlSkeletonLoader,
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
    loading: {
      type: Boolean,
      required: false,
      default: false,
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
    <gl-skeleton-loader v-if="loading" :width="300" :lines="3" />
    <gl-area-chart
      v-else
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
