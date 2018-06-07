<script>
  import { getSundays } from '~/lib/utils/datetime_utility';

  import { PRESET_TYPES } from '../../constants';

  import timelineTodayIndicator from '../timeline_today_indicator.vue';

  export default {
    presetType: PRESET_TYPES.MONTHS,
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
    computed: {
      headerSubItems() {
        return getSundays(this.timeframeItem);
      },
      headerSubItemClass() {
        const currentYear = this.currentDate.getFullYear();
        const currentMonth = this.currentDate.getMonth();
        const timeframeYear = this.timeframeItem.getFullYear();
        const timeframeMonth = this.timeframeItem.getMonth();

        // Show dark color text only for dates from current month and future months.
        return timeframeYear >= currentYear && timeframeMonth >= currentMonth ? 'label-dark' : '';
      },
      hasToday() {
        const timeframeYear = this.timeframeItem.getFullYear();
        const timeframeMonth = this.timeframeItem.getMonth();

        return this.currentDate.getMonth() === timeframeMonth &&
               this.currentDate.getFullYear() === timeframeYear;
      },
    },
    methods: {
      getSubItemValueClass(subItem) {
        const daysToClosestWeek = this.currentDate.getDate() - subItem.getDate();
        // Show dark color text only for upcoming dates
        // and current week date
        if (daysToClosestWeek <= 6 &&
            this.currentDate.getDate() >= subItem.getDate() &&
            this.currentDate.getFullYear() === subItem.getFullYear() &&
            this.currentDate.getMonth() === subItem.getMonth()) {
          return 'label-dark label-bold';
        } else if (subItem >= this.currentDate) {
          return 'label-dark';
        }
        return '';
      },
    },
  };
</script>

<template>
  <div
    class="item-sublabel"
    :class="headerSubItemClass"
  >
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
