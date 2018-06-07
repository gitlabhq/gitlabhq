<script>
  import { monthInWords } from '~/lib/utils/datetime_utility';

  import WeeksHeaderSubItem from './weeks_header_sub_item.vue';

  export default {
    components: {
      WeeksHeaderSubItem,
    },
    props: {
      timeframeIndex: {
        type: Number,
        required: true,
      },
      timeframeItem: {
        type: Date,
        required: true,
      },
      timeframe: {
        type: Array,
        required: true,
      },
      itemWidth: {
        type: Number,
        required: true,
      },
    },
    data() {
      const currentDate = new Date();
      currentDate.setHours(0, 0, 0, 0);

      const lastDayOfCurrentWeek = new Date(this.timeframeItem.getTime());
      lastDayOfCurrentWeek.setDate(lastDayOfCurrentWeek.getDate() + 7);

      return {
        currentDate,
        lastDayOfCurrentWeek,
      };
    },
    computed: {
      itemStyles() {
        return {
          width: `${this.itemWidth}px`,
        };
      },
      timelineHeaderLabel() {
        if (this.timeframeIndex === 0) {
          return `${this.timeframeItem.getFullYear()} ${monthInWords(this.timeframeItem, true)} ${this.timeframeItem.getDate()}`;
        }
        return `${monthInWords(this.timeframeItem, true)} ${this.timeframeItem.getDate()}`;
      },
      timelineHeaderClass() {
        if (this.currentDate >= this.timeframeItem &&
            this.currentDate <= this.lastDayOfCurrentWeek) {
          return 'label-dark label-bold';
        } else if (this.currentDate < this.lastDayOfCurrentWeek) {
          return 'label-dark';
        }
        return '';
      },
    },
  };
</script>

<template>
  <span
    class="timeline-header-item"
    :style="itemStyles"
  >
    <div
      class="item-label"
      :class="timelineHeaderClass"
    >
      {{ timelineHeaderLabel }}
    </div>
    <weeks-header-sub-item
      :timeframe-item="timeframeItem"
      :current-date="currentDate"
    />
  </span>
</template>
