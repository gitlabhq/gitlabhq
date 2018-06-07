<script>
import { PRESET_TYPES } from '../../constants';

import timelineTodayIndicator from '../timeline_today_indicator.vue';

export default {
  presetType: PRESET_TYPES.WEEKS,
  components: {
    timelineTodayIndicator,
  },
  props: {
    currentDate: {
      type: Date,
      required: true,
    },
    timeframeItem: {
      type: Date,
      required: true,
    },
  },
  data() {
    const timeframeItem = new Date(this.timeframeItem.getTime());
    const headerSubItems = new Array(7)
                              .fill()
                              .map(
                                (val, i) => new Date(
                                  timeframeItem.getFullYear(),
                                  timeframeItem.getMonth(),
                                  timeframeItem.getDate() + i,
                                ),
                              );

    return {
      headerSubItems,
    };
  },
  computed: {
    hasToday() {
      return (
        this.currentDate >= this.headerSubItems[0] &&
        this.currentDate <= this.headerSubItems[this.headerSubItems.length - 1]
      );
    },
  },
  methods: {
    getSubItemValueClass(subItem) {
      // Show dark color text only for current & upcoming dates
      if (subItem.getTime() === this.currentDate.getTime()) {
        return 'label-dark label-bold';
      } else if (subItem > this.currentDate) {
        return 'label-dark';
      }
      return '';
    },
  },
};
</script>

<template>
  <div class="item-sublabel">
    <span
      v-for="(subItem, index) in headerSubItems"
      :key="index"
      class="sublabel-value"
      :class="getSubItemValueClass(subItem)"
    >
      {{ subItem.getDate() }}
    </span>
    <timeline-today-indicator
      v-if="hasToday"
      :preset-type="$options.presetType"
      :current-date="currentDate"
      :timeframe-item="timeframeItem"
    />
  </div>
</template>
