<script>
import { GlChartSeriesLabel } from '@gitlab/ui/src/charts';

export default {
  name: 'FormattedTooltipContent',
  components: { GlChartSeriesLabel },
  props: {
    content: {
      required: true,
      type: Object,
    },
    formatValue: {
      required: true,
      type: Function,
    },
  },
};
</script>

<template>
  <div>
    <div
      v-for="(entry, label) in content"
      :key="label"
      class="gl-charts-tooltip-default-format-series"
    >
      <gl-chart-series-label
        :color="entry.color"
        class="gl-charts-tooltip-default-format-series-label"
        >{{ label }}</gl-chart-series-label
      >
      <div class="gl-charts-tooltip-default-format-series-value">
        {{ formatValue(label, entry.value) }}
      </div>
    </div>
  </div>
</template>
