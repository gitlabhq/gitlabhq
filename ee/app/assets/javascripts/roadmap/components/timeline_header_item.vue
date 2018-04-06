<script>
  import { monthInWords } from '~/lib/utils/datetime_utility';

  import timelineHeaderSubItem from './timeline_header_sub_item.vue';

  export default {
    components: {
      timelineHeaderSubItem,
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
      return {
        currentDate,
        currentYear: currentDate.getFullYear(),
        currentMonth: currentDate.getMonth(),
      };
    },
    computed: {
      itemStyles() {
        return {
          width: `${this.itemWidth}px`,
        };
      },
      timelineHeaderLabel() {
        const year = this.timeframeItem.getFullYear();
        const month = monthInWords(this.timeframeItem, true);

        // Show Year only if current timeframe has months between
        // two years and current timeframe item is first month
        // from one of the two years.
        //
        // End result of doing this is;
        //  2017 Nov, Dec, 2018 Jan, Feb, Mar
        if (this.timeframeIndex !== 0 &&
            this.timeframe[this.timeframeIndex - 1].getFullYear() === year) {
          return month;
        }

        return `${year} ${month}`;
      },
      timelineHeaderClass() {
        let itemLabelClass = '';

        const timeframeYear = this.timeframeItem.getFullYear();
        const timeframeMonth = this.timeframeItem.getMonth();

        // Show dark color text only if timeframe item year & month
        // are greater than current year.
        if (timeframeYear >= this.currentYear &&
            timeframeMonth >= this.currentMonth) {
          itemLabelClass += 'label-dark';
        }

        // Show bold text only if timeframe item year & month
        // is current year & month
        if (timeframeYear === this.currentYear &&
            timeframeMonth === this.currentMonth) {
          itemLabelClass += ' label-bold';
        }

        return itemLabelClass;
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
    <timeline-header-sub-item
      :timeframe-item="timeframeItem"
      :current-date="currentDate"
    />
  </span>
</template>
