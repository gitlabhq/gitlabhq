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
    unitOfDisplay: {
      type: String,
      required: true,
    },
  },
  methods: {
    formatMetricUsage(series) {
      const value =
        series.values[this.currentDataIndex] &&
        series.values[this.currentDataIndex].value;
      if (isNaN(value)) {
        return '-';
      }
      return `${formatRelevantDigits(value)} ${this.unitOfDisplay}`;
    },

    createSeriesString(index, series) {
      if (series.metricTag) {
        return `${series.metricTag} ${this.formatMetricUsage(series)}`;
      }
      return `${this.legendTitle} series ${index + 1} ${this.formatMetricUsage(
        series,
      )}`;
    },

    summaryMetrics(series) {
      return `Avg: ${formatRelevantDigits(series.average)} ${this.unitOfDisplay},
      Max: ${formatRelevantDigits(series.max)} ${this.unitOfDisplay}`;
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
          {{ createSeriesString(index, series) }}, {{ summaryMetrics(series) }}
        </td>
        <td v-else>
          {{ legendTitle }} {{ formatMetricUsage(series) }}, {{ summaryMetrics(series) }}
        </td>
      </tr>
    </table>
  </div>
</template>
