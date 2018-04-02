<script>
import { dateFormat, timeFormat } from '../../utils/date_time_formatters';
import { formatRelevantDigits } from '../../../lib/utils/number_utils';
import icon from '../../../vue_shared/components/icon.vue';

export default {
  components: {
    icon,
  },
  props: {
    currentXCoordinate: {
      type: Number,
      required: true,
    },
    currentData: {
      type: Object,
      required: true,
    },
    deploymentFlagData: {
      type: Object,
      required: false,
      default: null,
    },
    graphHeight: {
      type: Number,
      required: true,
    },
    graphHeightOffset: {
      type: Number,
      required: true,
    },
    realPixelRatio: {
      type: Number,
      required: true,
    },
    showFlagContent: {
      type: Boolean,
      required: true,
    },
    timeSeries: {
      type: Array,
      required: true,
    },
    unitOfDisplay: {
      type: String,
      required: true,
    },
    currentDataIndex: {
      type: Number,
      required: true,
    },
    legendTitle: {
      type: String,
      required: true,
    },
  },
  computed: {
    formatTime() {
      return this.deploymentFlagData
        ? timeFormat(this.deploymentFlagData.time)
        : timeFormat(this.currentData.time);
    },
    formatDate() {
      return this.deploymentFlagData
        ? dateFormat(this.deploymentFlagData.time)
        : dateFormat(this.currentData.time);
    },
    cursorStyle() {
      const xCoordinate = this.deploymentFlagData
        ? this.deploymentFlagData.xPos
        : this.currentXCoordinate;

      const offsetTop = 20 * this.realPixelRatio;
      const offsetLeft = (70 + xCoordinate) * this.realPixelRatio;
      const height = (this.graphHeight - this.graphHeightOffset) * this.realPixelRatio;

      return {
        top: `${offsetTop}px`,
        left: `${offsetLeft}px`,
        height: `${height}px`,
      };
    },
    flagOrientation() {
      if (this.currentXCoordinate * this.realPixelRatio > 120) {
        return 'left';
      }
      return 'right';
    },
  },
  methods: {
    seriesMetricValue(series) {
      const index = this.deploymentFlagData
        ? this.deploymentFlagData.seriesIndex
        : this.currentDataIndex;
      const value = series.values[index] && series.values[index].value;
      if (isNaN(value)) {
        return '-';
      }
      return `${formatRelevantDigits(value)}${this.unitOfDisplay}`;
    },
    seriesMetricLabel(index, series) {
      if (this.timeSeries.length < 2) {
        return this.legendTitle;
      }
      if (series.metricTag) {
        return series.metricTag;
      }
      return `series ${index + 1}`;
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
  <div
    class="prometheus-graph-cursor"
    :style="cursorStyle"
  >
    <div
      v-if="showFlagContent"
      class="prometheus-graph-flag popover"
      :class="flagOrientation"
    >
      <div class="arrow"></div>
      <div class="popover-title">
        <h5 v-if="deploymentFlagData">
          Deployed
        </h5>
        {{ formatDate }} at
        <strong>{{ formatTime }}</strong>
      </div>
      <div
        v-if="deploymentFlagData"
        class="popover-content deploy-meta-content"
      >
        <div>
          <icon
            name="commit"
            :size="12"
          />
          <a :href="deploymentFlagData.commitUrl">
            {{ deploymentFlagData.sha.slice(0, 8) }}
          </a>
        </div>
        <div
          v-if="deploymentFlagData.tag"
        >
          <icon
            name="label"
            :size="12"
          />
          <a :href="deploymentFlagData.tagUrl">
            {{ deploymentFlagData.ref }}
          </a>
        </div>
      </div>
      <div class="popover-content">
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
                  :stroke="series.lineColor"
                  :stroke-dasharray="strokeDashArray(series.lineStyle)"
                  stroke-width="4"
                  x1="0"
                  x2="15"
                  y1="2"
                  y2="2"
                />
              </svg>
            </td>
            <td>{{ series.track }} {{ seriesMetricLabel(index, series) }}</td>
            <td>
              <strong>{{ seriesMetricValue(series) }}</strong>
            </td>
          </tr>
        </table>
      </div>
    </div>
  </div>
</template>
