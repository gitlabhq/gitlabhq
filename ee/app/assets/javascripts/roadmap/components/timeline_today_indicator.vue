<script>
  import { totalDaysInMonth } from '~/lib/utils/datetime_utility';

  import eventHub from '../event_hub';

  export default {
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
      return {
        todayBarStyles: '',
        todayBarReady: false,
      };
    },
    mounted() {
      eventHub.$on('epicsListRendered', this.handleEpicsListRender);
    },
    beforeDestroy() {
      eventHub.$off('epicsListRendered', this.handleEpicsListRender);
    },
    methods: {
      /**
       * This method takes height of current shell
       * and renders vertical line over the area where
       * today falls in current timeline
       */
      handleEpicsListRender({ height }) {
        // Get total days of current timeframe Item
        const daysInMonth = totalDaysInMonth(this.timeframeItem);
        // Get size in % from current date and days in month.
        const left = Math.floor((this.currentDate.getDate() / daysInMonth) * 100);

        // Set styles and reduce scrollbar height from total shell height.
        this.todayBarStyles = `height: ${height}px; left: ${left}%;`;
        this.todayBarReady = true;
      },
    },
  };
</script>

<template>
  <span
    v-if="todayBarReady"
    class="today-bar"
    :style="todayBarStyles"
  >
  </span>
</template>
