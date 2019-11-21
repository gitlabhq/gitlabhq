<script>
import { formatDate, secondsToMilliseconds } from '~/lib/utils/datetime_utility';
import { GlSparklineChart } from '@gitlab/ui/dist/charts';

export default {
  name: 'MemoryGraph',
  components: {
    GlSparklineChart,
  },
  props: {
    metrics: { type: Array, required: true },
    width: { type: Number, required: true },
    height: { type: Number, required: true },
  },
  computed: {
    chartData() {
      return this.metrics.map(([x, y]) => [
        this.getFormattedDeploymentTime(x),
        this.getMemoryUsage(y),
      ]);
    },
  },
  methods: {
    getFormattedDeploymentTime(timestamp) {
      return formatDate(new Date(secondsToMilliseconds(timestamp)), 'mmm dd yyyy HH:MM:s');
    },
    getMemoryUsage(MBs) {
      return Number(MBs).toFixed(2);
    },
  },
};
</script>

<template>
  <div class="memory-graph-container p-1" :style="{ width: `${width}px` }">
    <gl-sparkline-chart
      :height="height"
      :tooltip-label="__('MB')"
      :show-last-y-value="false"
      :data="chartData"
    />
  </div>
</template>
