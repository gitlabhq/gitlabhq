<script>
  import { monthInWords } from '~/lib/utils/datetime_utility';

  import { EPIC_DETAILS_CELL_WIDTH, TIMELINE_CELL_MIN_WIDTH } from '../constants';

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
      shellWidth: {
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
      thStyles() {
        const timeframeLength = this.timeframe.length;

        // Calculate minimum width for single cell
        // based on total number of months in current timeframe
        // and available shellWidth
        const minWidth =
          Math.ceil((this.shellWidth - EPIC_DETAILS_CELL_WIDTH) / timeframeLength);

        // When shellWidth is too low, we need to obey global
        // minimum cell width.
        if (minWidth < TIMELINE_CELL_MIN_WIDTH) {
          return `min-width: ${TIMELINE_CELL_MIN_WIDTH}px;`;
        }

        return `min-width: ${minWidth}px;`;
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
  <th
    class="timeline-header-item"
    :style="thStyles"
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
  </th>
</template>
