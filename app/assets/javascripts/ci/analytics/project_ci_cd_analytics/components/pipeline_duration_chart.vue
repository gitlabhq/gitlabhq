<script>
import { GlDashboardPanel } from '@gitlab/ui';
import { GlLineChart } from '@gitlab/ui/src/charts';
import { s__ } from '~/locale';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import { formatPipelineDuration, formatPipelineDurationForAxis } from '../../utils';

export default {
  name: 'PipelineDurationChart',
  components: {
    GlDashboardPanel,
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
        { name: s__('Pipeline|Median (50th percentile)'), data: [] },
        { name: s__('Pipeline|95th percentile'), data: [] },
      ];

      this.timeSeries.forEach(({ label, durationStatistics }) => {
        durationSeries[0].data.push([label, durationStatistics.p50]);
        durationSeries[1].data.push([label, durationStatistics.p95]);
      });

      return durationSeries;
    },
  },
  methods: {
    formatDate(isoDateStr) {
      if (isoDateStr) {
        return localeDateFormat.asDate.format(new Date(isoDateStr));
      }
      return '';
    },
    formatPipelineDuration(seconds) {
      return formatPipelineDuration(seconds);
    },
  },
  lineChartOptions: {
    yAxis: {
      name: s__('Pipeline|Minutes'),
      type: 'value',
      axisLabel: {
        formatter: (seconds) => {
          return formatPipelineDurationForAxis(seconds);
        },
      },
    },
    xAxis: {
      name: s__('Pipeline|Time'),
      type: 'category',
    },
  },
};
</script>
<template>
  <gl-dashboard-panel :title="s__('Pipeline|Duration')" :loading="loading">
    <template #body>
      <gl-line-chart
        :data="data"
        :option="$options.lineChartOptions"
        :include-legend-avg-max="false"
      >
        <template #tooltip-title="{ params }">
          <template v-if="params && params.value">{{ formatDate(params.value) }}</template>
        </template>
        <template #tooltip-value="{ value }">
          {{ formatPipelineDuration(value) }}
        </template>
      </gl-line-chart>
    </template>
  </gl-dashboard-panel>
</template>
