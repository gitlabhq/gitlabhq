<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { engineeringNotation } from '@gitlab/ui/src/utils/number_utils';
import { GlLineChart } from '@gitlab/ui/dist/charts';
import { s__ } from '~/locale';
import { stringifyTime, parseSeconds } from '~/lib/utils/datetime/date_format_utility';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';

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
    formatDuration(seconds) {
      return stringifyTime(parseSeconds(seconds, { daysPerWeek: 7, hoursPerDay: 24 }));
    },
  },
  lineChartOptions: {
    yAxis: {
      name: s__('Pipeline|Minutes'),
      type: 'value',
      axisLabel: {
        formatter: (seconds) => {
          const minutes = seconds / 60;
          // using engineering notation for small amounts is strange, as we'd render "milliminutes"
          if (minutes < 1) {
            return minutes.toFixed(2).replace(/\.?0*$/, '');
          }
          return engineeringNotation(minutes, 2);
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
  <div class="gl-border gl-mb-5 gl-border-default gl-p-5">
    <h3 class="gl-heading-4">{{ s__('Pipeline|Duration') }}</h3>
    <gl-loading-icon v-if="loading" size="xl" class="gl-mb-5" />
    <gl-line-chart
      v-else
      :data="data"
      :option="$options.lineChartOptions"
      :include-legend-avg-max="false"
    >
      <template #tooltip-title="{ params }">
        <template v-if="params && params.value">{{ formatDate(params.value) }}</template>
      </template>
      <template #tooltip-value="{ value }">
        {{ formatDuration(value) }}
      </template>
    </gl-line-chart>
  </div>
</template>
