<script>
import { totalDaysInMonth, dayInQuarter, totalDaysInQuarter } from '~/lib/utils/datetime_utility';

import { EPIC_DETAILS_CELL_WIDTH, PRESET_TYPES } from '../constants';

import eventHub from '../event_hub';

export default {
  props: {
    presetType: {
      type: String,
      required: true,
    },
    currentDate: {
      type: Date,
      required: true,
    },
    timeframeItem: {
      type: [Date, Object],
      required: true,
    },
  },
  data() {
    return {
      todayBarStyles: '',
      todayBarReady: false,
    };
  },
  mounted() {
    eventHub.$on('epicsListRendered', this.handleEpicsListRender);
    eventHub.$on('epicsListScrolled', this.handleEpicsListScroll);
  },
  beforeDestroy() {
    eventHub.$off('epicsListRendered', this.handleEpicsListRender);
    eventHub.$off('epicsListScrolled', this.handleEpicsListScroll);
  },
  methods: {
    /**
     * This method takes height of current shell
     * and renders vertical line over the area where
     * today falls in current timeline
     */
    handleEpicsListRender({ height }) {
      let left = 0;

      // Get total days of current timeframe Item and then
      // get size in % from current date and days in range
      // based on the current presetType
      if (this.presetType === PRESET_TYPES.QUARTERS) {
        left = Math.floor(
          dayInQuarter(this.currentDate, this.timeframeItem.range) /
            totalDaysInQuarter(this.timeframeItem.range) *
            100,
        );
      } else if (this.presetType === PRESET_TYPES.MONTHS) {
        left = Math.floor(this.currentDate.getDate() / totalDaysInMonth(this.timeframeItem) * 100);
      } else if (this.presetType === PRESET_TYPES.WEEKS) {
        left = Math.floor(((this.currentDate.getDay() + 1) / 7 * 100) - 7);
      }

      // We add 20 to height to ensure that
      // today indicator goes past the bottom
      // edge of the browser even when
      // scrollbar is present
      this.todayBarStyles = {
        height: `${height + 20}px`,
        left: `${left}%`,
      };
      this.todayBarReady = true;
    },
    handleEpicsListScroll() {
      const indicatorX = this.$el.getBoundingClientRect().x;
      const rootOffsetLeft = this.$root.$el.offsetLeft;

      // 3px to compensate size of bubble on top of Indicator
      this.todayBarReady = (indicatorX - rootOffsetLeft) >= (EPIC_DETAILS_CELL_WIDTH + 3);
    },
  },
};
</script>

<template>
  <span
    class="today-bar"
    :class="{ 'invisible': !todayBarReady }"
    :style="todayBarStyles"
  >
  </span>
</template>
