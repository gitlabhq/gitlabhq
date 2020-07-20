<script>
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { s__ } from '~/locale';
import ResizableChartContainer from '~/vue_shared/components/resizable_chart/resizable_chart_container.vue';
import { CHART_CONTAINER_HEIGHT } from '../constants';

export default {
  components: {
    GlAreaChart,
    ResizableChartContainer,
  },
  props: {
    chartData: {
      type: Array,
      required: true,
    },
  },
  areaChartOptions: {
    xAxis: {
      name: s__('Pipeline|Date'),
      type: 'category',
    },
    yAxis: {
      name: s__('Pipeline|Pipelines'),
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
      <gl-area-chart
        slot-scope="{ width }"
        :width="width"
        :height="$options.chartContainerHeight"
        :data="chartData"
        :include-legend-avg-max="false"
        :option="$options.areaChartOptions"
      />
    </resizable-chart-container>
  </div>
</template>
