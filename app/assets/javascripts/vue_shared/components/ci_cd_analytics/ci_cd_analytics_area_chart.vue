<script>
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import ResizableChartContainer from '~/vue_shared/components/resizable_chart/resizable_chart_container.vue';
import { CHART_CONTAINER_HEIGHT } from './constants';

export default {
  name: 'CiCdAnalyticsAreaChart',
  components: {
    GlAreaChart,
    ResizableChartContainer,
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
    <resizable-chart-container>
      <template #default="{ width }">
        <gl-area-chart
          v-bind="$attrs"
          :width="width"
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
      </template>
    </resizable-chart-container>
  </div>
</template>
