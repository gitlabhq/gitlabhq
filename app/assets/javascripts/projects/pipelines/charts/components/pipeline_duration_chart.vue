<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { GlLineChart } from '@gitlab/ui/dist/charts';
import { s__ } from '~/locale';

export default {
  components: {
    GlLoadingIcon,
    GlLineChart,
  },
  props: {
    timeSeries: {
      type: Array,
      required: false,
      default: () => [],
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    data() {
      const durationSeries = [
        { name: s__('Pipeline|Mean (50th percentile)'), data: [] },
        { name: s__('Pipeline|95th percentile'), data: [] },
      ];

      this.timeSeries.forEach(({ label, durationStatistics }) => {
        durationSeries[0].data.push([label, durationStatistics.p50]);
        durationSeries[1].data.push([label, durationStatistics.p95]);
      });

      return durationSeries;
    },
  },
  lineChartOptions: {
    yAxis: {
      name: s__('Pipeline|Seconds'),
    },
    xAxis: {
      name: s__('Pipeline|Time'),
      type: 'category',
    },
  },
};
</script>
<template>
  <div class="gl-border gl-mb-5 gl-border-default gl-p-5">
    <h3 class="gl-heading-4">{{ s__('Pipeline|Duration') }}</h3>
    <gl-loading-icon v-if="loading" size="xl" class="gl-mb-5" />
    <gl-line-chart
      v-else
      :data="data"
      :option="$options.lineChartOptions"
      :include-legend-avg-max="false"
    />
  </div>
</template>
