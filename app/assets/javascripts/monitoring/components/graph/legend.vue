<script>
import { formatRelevantDigits } from '~/lib/utils/number_utils';

export default {
  props: {
    legendTitle: {
      type: String,
      required: true,
    },
    timeSeries: {
      type: Array,
      required: true,
    },
    currentDataIndex: {
      type: Number,
      required: true,
    },
  },
  methods: {
    summaryMetrics(series) {
      return `Avg: ${formatRelevantDigits(series.average)} · Max: ${formatRelevantDigits(series.max)}`;
    },

    strokeDashArray(type) {
      if (type === 'dashed') return '6, 3';
      if (type === 'dotted') return '3, 3';
      return null;
    },
  },
};
</script>
<template>
  <div class="prometheus-graph-legends prepend-left-10">
    <table class="prometheus-table">
      <tr
        v-for="(series, index) in timeSeries"
        :key="index"
      >
        <td>
          <strong>{{ series.track }}</strong>
        </td>
        <td>
          <svg
            width="15"
            height="6"
          >
            <line
              :stroke-dasharray="strokeDashArray(series.lineStyle)"
              :stroke="series.lineColor"
              stroke-width="4"
              :x1="0"
              :x2="15"
              :y1="2"
              :y2="2"
            />
          </svg>
        </td>
        <td
          class="legend-metric-title"
          v-if="timeSeries.length > 1"
        >
          <template v-if="series.metricTag">
            <strong>{{ series.metricTag }}</strong> {{ summaryMetrics(series) }}
          </template>
          <template v-else>
            <strong>{{ legendTitle }}</strong>
            series {{ index + 1 }} {{ summaryMetrics(series) }}
          </template>
        </td>
        <td v-else>
          <strong>{{ legendTitle }}</strong> {{ summaryMetrics(series) }}
        </td>
      </tr>
    </table>
  </div>
</template>
