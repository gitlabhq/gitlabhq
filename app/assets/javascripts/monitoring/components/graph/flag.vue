<script>
import { dateFormat, timeFormat } from '../../utils/date_time_formatters';
import { formatRelevantDigits } from '../../../lib/utils/number_utils';
import Icon from '../../../vue_shared/components/icon.vue';
import TrackLine from './track_line.vue';

export default {
  components: {
    Icon,
    TrackLine,
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
    legendTitle: {
      type: String,
      required: true,
    },
    currentCoordinates: {
      type: Object,
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
    seriesMetricValue(seriesIndex, series) {
      const indexFromCoordinates = this.currentCoordinates[series.metricTag]
      ? this.currentCoordinates[series.metricTag].currentDataIndex : 0;
      const index = this.deploymentFlagData
        ? this.deploymentFlagData.seriesIndex
        : indexFromCoordinates;
      const value = series.values[index] && series.values[index].value;
      if (Number.isNaN(value)) {
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
  },
};
</script>

<template>
  <div
    :style="cursorStyle"
    class="prometheus-graph-cursor"
  >
    <div
      v-if="showFlagContent"
      :class="flagOrientation"
      class="prometheus-graph-flag popover"
    >
      <div class="arrow-shadow"></div>
      <div class="arrow"></div>
      <div class="popover-header">
        <h5 v-if="deploymentFlagData">
          Deployed
        </h5>
        {{ formatDate }}
        <strong>{{ formatTime }}</strong>
      </div>
      <div
        v-if="deploymentFlagData"
        class="popover-body deploy-meta-content"
      >
        <div>
          <icon
            :size="12"
            name="commit"
          />
          <a :href="deploymentFlagData.commitUrl">
            {{ deploymentFlagData.sha.slice(0, 8) }}
          </a>
        </div>
        <div
          v-if="deploymentFlagData.tag"
        >
          <icon
            :size="12"
            name="label"
          />
          <a :href="deploymentFlagData.tagUrl">
            {{ deploymentFlagData.ref }}
          </a>
        </div>
      </div>
      <div class="popover-body">
        <table class="prometheus-table">
          <tr
            v-for="(series, index) in timeSeries"
            :key="index"
          >
            <track-line :track="series"/>
            <td>
              {{ series.track }} {{ seriesMetricLabel(index, series) }}
            </td>
            <td>
              <strong>{{ seriesMetricValue(index, series) }}</strong>
            </td>
          </tr>
        </table>
      </div>
    </div>
  </div>
</template>
