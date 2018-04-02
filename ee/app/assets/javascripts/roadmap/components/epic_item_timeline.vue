<script>
  import { totalDaysInMonth } from '~/lib/utils/datetime_utility';
  import tooltip from '~/vue_shared/directives/tooltip';

  import {
    EPIC_DETAILS_CELL_WIDTH,
    TIMELINE_CELL_MIN_WIDTH,
    TIMELINE_END_OFFSET_FULL,
    TIMELINE_END_OFFSET_HALF,
  } from '../constants';

  export default {
    directives: {
      tooltip,
    },
    props: {
      timeframe: {
        type: Array,
        required: true,
      },
      timeframeItem: {
        type: Date,
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
      /**
       * Check if current timeline cell has start date for current epic
       */
      hasStartDate() {
        return this.epic.startDate.getMonth() === this.timeframeItem.getMonth() &&
               this.epic.startDate.getFullYear() === this.timeframeItem.getFullYear();
      },
      /**
       * In case startDate for any epic is undefined or is out of range
       * for current timeframe, we have to provide specific offset while
       * positioning it to ensure that;
       *
       * 1. Timeline bar starts at correct position based on start date.
       * 2. Bar starts exactly at the start of cell in case start date is `1`.
       * 3. A "triangle" shape is shown at the beginning of timeline bar
       *    when startDate is out of range.
       */
      getTimelineBarStartOffset() {
        const daysInMonth = totalDaysInMonth(this.timeframeItem);
        const startDate = this.epic.startDate.getDate();
        let offset = '';

        if (this.epic.startDateOutOfRange ||
            (this.epic.startDateUndefined && this.epic.endDateOutOfRange)) {
          // If Epic startDate is out of timeframe range
          // OR
          // Epic startDate is undefined AND Epic endDate is out of timeframe range
          // no offset is needed.
          offset = '';
        } else if (startDate === 1) {
          // If Epic startDate is first day of the month
          // Set offset to 0.
          offset = 'left: 0;';
        } else {
          // Calculate proportional offset based on startDate and total days in
          // current month.
          offset = `left: ${Math.floor((startDate / daysInMonth) * 100)}%;`;
        }

        return offset;
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

        if ((this.epic.startDateOutOfRange && this.epic.endDateOutOfRange) ||
            (this.epic.startDateUndefined && this.epic.endDateOutOfRange)) {
          // If Epic startDate is undefined or out of range
          // AND
          // endDate is out of range
          // Reduce offset size from the width to compensate for fadeout of timelinebar
          // and/or showing triangle at the end and beginning
          offset = TIMELINE_END_OFFSET_FULL;
        } else if (this.epic.endDateOutOfRange) {
          // If Epic end date is out of range
          // Reduce offset size from the width to compensate for triangle (which is sized at 8px)
          offset = TIMELINE_END_OFFSET_HALF;
        } else {
          // No offset needed if all dates are defined.
          offset = 0;
        }

        return offset;
      },
      /**
       * Check if current timeframe is under the range of Epic endDate
       */
      isTimeframeUnderEndDate(timeframeItem, epicEndDate) {
        return timeframeItem.getYear() <= epicEndDate.getYear() &&
               timeframeItem.getMonth() === epicEndDate.getMonth();
      },
      /**
       * Get width for timeline bar for current cell (representing a month)
       * Based on total days in the month and width of month on UI
       */
      getBarWidthForMonth(cellWidth, daysInMonth, date) {
        const dayWidth = cellWidth / daysInMonth;
        const barWidth = date === daysInMonth ? cellWidth : dayWidth * date;

        return Math.min(cellWidth, barWidth);
      },
      /**
       * This method is externally only called when current timeframe cell has timeline
       * bar to show. So when this method is called, we iterate over entire timeframe
       * array starting from current timeframeItem.
       *
       * For eg;
       *  If timeframe range for 6 months is;
       *    2017 Oct, 2017 Nov, 2017 Dec, 2018 Jan, 2018 Feb, 2018 Mar
       *
       *  And if Epic starts in 2017 Dec and ends in 2018 Feb.
       *
       *  Then this method will iterate over timeframe as;
       *    2017 Dec => 2018 Feb
       *  And will add up width(see 1.) for timeline bar for each month in iteration
       *  based on provided start and end dates.
       *
       *  1. Width from date is calculated by totalWidthCell / totalDaysInMonth = widthOfSingleDay
       *     and then dateOfMonth x widthOfSingleDay = totalBarWidth
       */
      getTimelineBarWidth() {
        let timelineBarWidth = 0;

        const indexOfCurrentMonth = this.timeframe.indexOf(this.timeframeItem);
        const cellWidth = this.getCellWidth();
        const offsetEnd = this.getTimelineBarEndOffset();
        const epicStartDate = this.epic.startDate;
        const epicEndDate = this.epic.endDate;

        // Start iteration from current month
        for (let i = indexOfCurrentMonth; i < this.timeframe.length; i += 1) {
          // Get total days for current month
          const daysInMonth = totalDaysInMonth(this.timeframe[i]);

          if (i === indexOfCurrentMonth) {
            // If this is current month
            if (this.isTimeframeUnderEndDate(this.timeframe[i], epicEndDate)) {
              // If Epic endDate falls under the range of current timeframe month
              // then get width for number of days between start and end dates (inclusive)
              timelineBarWidth += this.getBarWidthForMonth(
                cellWidth,
                daysInMonth,
                ((epicEndDate.getDate() - epicStartDate.getDate()) + 1),
              );
              // Break as Epic start and end date fall within current timeframe month itself!
              break;
            } else {
              // Epic end date does NOT fall in current month.

              // If start date is first day of the month,
              // we need width of full cell (i.e. total days of month)
              // otherwise, we need width only for date from total days of month.
              const date = epicStartDate.getDate() === 1 ?
                daysInMonth : daysInMonth - epicStartDate.getDate();
              timelineBarWidth += this.getBarWidthForMonth(cellWidth, daysInMonth, date);
            }
          } else if (this.isTimeframeUnderEndDate(this.timeframe[i], epicEndDate)) {
            // If this is NOT current month but epicEndDate falls under
            // current timeframe month then calculate width
            // based on date of the month
            timelineBarWidth += this.getBarWidthForMonth(
              cellWidth,
              daysInMonth,
              epicEndDate.getDate(),
            );
            // Break as Epic end date falls within current timeframe month!
            break;
          } else {
            // This is neither current month,
            // nor does the Epic end date fall under current timeframe month
            // add width for entire cell of current timeframe.
            timelineBarWidth += this.getBarWidthForMonth(cellWidth, daysInMonth, daysInMonth);
          }
        }

        // Reduce any offset from total width and round it off.
        return timelineBarWidth - offsetEnd;
      },
      /**
       * Renders timeline bar only if current
       * timeframe item has startDate for the epic.
       */
      renderTimelineBar() {
        if (this.hasStartDate()) {
          this.timelineBarStyles = `width: ${this.getTimelineBarWidth()}px; ${this.getTimelineBarStartOffset()}`;
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
