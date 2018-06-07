<script>
import tooltip from '~/vue_shared/directives/tooltip';

import QuartersPresetMixin from '../mixins/quarters_preset_mixin';
import MonthsPresetMixin from '../mixins/months_preset_mixin';
import WeeksPresetMixin from '../mixins/weeks_preset_mixin';

import {
  EPIC_DETAILS_CELL_WIDTH,
  TIMELINE_CELL_MIN_WIDTH,
  TIMELINE_END_OFFSET_FULL,
  TIMELINE_END_OFFSET_HALF,
  PRESET_TYPES,
} from '../constants';

export default {
  directives: {
    tooltip,
  },
  mixins: [
    QuartersPresetMixin,
    MonthsPresetMixin,
    WeeksPresetMixin,
  ],
  props: {
    presetType: {
      type: String,
      required: true,
    },
    timeframe: {
      type: Array,
      required: true,
    },
    timeframeItem: {
      type: [Date, Object],
      required: true,
    },
    epic: {
      type: Object,
      required: true,
    },
    shellWidth: {
      type: Number,
      required: true,
    },
    itemWidth: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      timelineBarReady: false,
      timelineBarStyles: '',
    };
  },
  computed: {
    itemStyles() {
      return {
        width: `${this.itemWidth}px`,
      };
    },
    showTimelineBar() {
      return this.hasStartDate();
    },
  },
  watch: {
    shellWidth: function shellWidth() {
      // Render timeline bar only when shellWidth is updated.
      this.renderTimelineBar();
    },
  },
  methods: {
    /**
     * Gets cell width based on total number months for
     * current timeframe and shellWidth excluding details cell width.
     *
     * In case cell width is too narrow, we have fixed minimum
     * cell width (TIMELINE_CELL_MIN_WIDTH) to obey.
     */
    getCellWidth() {
      const minWidth = (this.shellWidth - EPIC_DETAILS_CELL_WIDTH) / this.timeframe.length;

      return Math.max(minWidth, TIMELINE_CELL_MIN_WIDTH);
    },
    hasStartDate() {
      if (this.presetType === PRESET_TYPES.QUARTERS) {
        return this.hasStartDateForQuarter();
      } else if (this.presetType === PRESET_TYPES.MONTHS) {
        return this.hasStartDateForMonth();
      } else if (this.presetType === PRESET_TYPES.WEEKS) {
        return this.hasStartDateForWeek();
      }
      return false;
    },
    getTimelineBarEndOffsetHalf() {
      if (this.presetType === PRESET_TYPES.QUARTERS) {
        return TIMELINE_END_OFFSET_HALF;
      } else if (this.presetType === PRESET_TYPES.MONTHS) {
        return TIMELINE_END_OFFSET_HALF;
      } else if (this.presetType === PRESET_TYPES.WEEKS) {
        return this.getTimelineBarEndOffsetHalfForWeek();
      }
      return 0;
    },
    /**
     * In case startDate or endDate for any epic is undefined or is out of range
     * for current timeframe, we have to provide specific offset while
     * setting width to ensure that;
     *
     * 1. Timeline bar ends at correct position based on end date.
     * 2. A "triangle" shape is shown at the end of timeline bar
     *    when endDate is out of range.
     */
    getTimelineBarEndOffset() {
      let offset = 0;

      if (
        (this.epic.startDateOutOfRange && this.epic.endDateOutOfRange) ||
        (this.epic.startDateUndefined && this.epic.endDateOutOfRange)
      ) {
        // If Epic startDate is undefined or out of range
        // AND
        // endDate is out of range
        // Reduce offset size from the width to compensate for fadeout of timelinebar
        // and/or showing triangle at the end and beginning
        offset = TIMELINE_END_OFFSET_FULL;
      } else if (this.epic.endDateOutOfRange) {
        // If Epic end date is out of range
        // Reduce offset size from the width to compensate for triangle (which is sized at 8px)
        offset = this.getTimelineBarEndOffsetHalf();
      } else {
        // No offset needed if all dates are defined.
        offset = 0;
      }

      return offset;
    },
    /**
     * Renders timeline bar only if current
     * timeframe item has startDate for the epic.
     */
    renderTimelineBar() {
      if (this.hasStartDate()) {
        if (this.presetType === PRESET_TYPES.QUARTERS) {
          this.timelineBarStyles = `width: ${this.getTimelineBarWidthForQuarters()}px; ${this.getTimelineBarStartOffsetForQuarters()}`;
        } else if (this.presetType === PRESET_TYPES.MONTHS) {
          this.timelineBarStyles = `width: ${this.getTimelineBarWidthForMonths()}px; ${this.getTimelineBarStartOffsetForMonths()}`;
        } else if (this.presetType === PRESET_TYPES.WEEKS) {
          this.timelineBarStyles = `width: ${this.getTimelineBarWidthForWeeks()}px; ${this.getTimelineBarStartOffsetForWeeks()}`;
        }
        this.timelineBarReady = true;
      }
    },
  },
};
</script>

<template>
  <span
    class="epic-timeline-cell"
    :style="itemStyles"
  >
    <div class="timeline-bar-wrapper">
      <a
        v-if="showTimelineBar"
        class="timeline-bar"
        :href="epic.webUrl"
        :class="{
          'start-date-undefined': epic.startDateUndefined,
          'start-date-outside': epic.startDateOutOfRange,
          'end-date-undefined': epic.endDateUndefined,
          'end-date-outside': epic.endDateOutOfRange,
        }"
        :style="timelineBarStyles"
      >
      </a>
    </div>
  </span>
</template>
