<script>
  import { getSundays } from '~/lib/utils/datetime_utility';

  import timelineTodayIndicator from './timeline_today_indicator.vue';

  export default {
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
        // Show light color text for dates which are
        // older than today
        if (subItem < this.currentDate) {
          return 'value-light';
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
      :timeframe-item="timeframeItem"
      :current-date="currentDate"
    />
  </div>
</template>
