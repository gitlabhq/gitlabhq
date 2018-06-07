import { totalDaysInMonth } from '~/lib/utils/datetime_utility';

import { TIMELINE_END_OFFSET_HALF } from '../constants';

export default {
  methods: {
    /**
     * Check if current epic starts within current month (timeline cell)
     */
    hasStartDateForMonth() {
      return (
        this.epic.startDate.getMonth() === this.timeframeItem.getMonth() &&
        this.epic.startDate.getFullYear() === this.timeframeItem.getFullYear()
      );
    },
    /**
     * Check if current epic ends within current month (timeline cell)
     */
    isTimeframeUnderEndDateForMonth(timeframeItem, epicEndDate) {
      return (
        timeframeItem.getYear() <= epicEndDate.getYear() &&
        timeframeItem.getMonth() === epicEndDate.getMonth()
      );
    },
    /**
     * Return timeline bar width for current month (timeline cell) based on
     * cellWidth, days in month and date of the month
     */
    getBarWidthForSingleMonth(cellWidth, daysInMonth, date) {
      const dayWidth = cellWidth / daysInMonth;
      const barWidth = date === daysInMonth ? cellWidth : dayWidth * date;

      return Math.min(cellWidth, barWidth);
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
    getTimelineBarStartOffsetForMonths() {
      const daysInMonth = totalDaysInMonth(this.timeframeItem);
      const startDate = this.epic.startDate.getDate();

      if (
        this.epic.startDateOutOfRange ||
        (this.epic.startDateUndefined && this.epic.endDateOutOfRange)
      ) {
        // If Epic startDate is out of timeframe range
        // OR
        // Epic startDate is undefined AND Epic endDate is out of timeframe range
        // no offset is needed.
        return '';
      } else if (startDate === 1) {
        // If Epic startDate is first day of the month
        // Set offset to 0.
        return 'left: 0;';
      }

      // If Epic end date is out of range
      const lastTimeframeItem = this.timeframe[this.timeframe.length - 1];
      // Check if Epic start date falls within last month of the timeframe
      if (
        this.epic.startDate.getMonth() === lastTimeframeItem.getMonth() &&
        this.epic.startDate.getFullYear() === lastTimeframeItem.getFullYear()
      ) {
        // Compensate for triangle size
        return `right: ${TIMELINE_END_OFFSET_HALF}px;`;
      }
      // Calculate proportional offset based on startDate and total days in
      // current month.
      return `left: ${startDate / daysInMonth * 100}%;`;
    },
    /**
     * This method is externally only called when current timeframe cell has timeline
     * bar to show. So when this method is called, we iterate over entire timeframe
     * array starting from current timeframeItem.
     *
     * For eg;
     *  If timeframe range for 7 months is;
     *    2017 Oct, 2017 Nov, 2017 Dec, 2018 Jan, 2018 Feb, 2018 Mar, 2018 Apr
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
    getTimelineBarWidthForMonths() {
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
          if (this.isTimeframeUnderEndDateForMonth(this.timeframe[i], epicEndDate)) {
            // If Epic endDate falls under the range of current timeframe month
            // then get width for number of days between start and end dates (inclusive)
            timelineBarWidth += this.getBarWidthForSingleMonth(
              cellWidth,
              daysInMonth,
              epicEndDate.getDate() - epicStartDate.getDate() + 1,
            );
            // Break as Epic start and end date fall within current timeframe month itself!
            break;
          } else {
            // Epic end date does NOT fall in current month.

            // If start date is first day of the month,
            // we need width of full cell (i.e. total days of month)
            // otherwise, we need width only for date from total days of month.
            const date =
              epicStartDate.getDate() === 1 ? daysInMonth : daysInMonth - epicStartDate.getDate();
            timelineBarWidth += this.getBarWidthForSingleMonth(cellWidth, daysInMonth, date);
          }
        } else if (this.isTimeframeUnderEndDateForMonth(this.timeframe[i], epicEndDate)) {
          // If this is NOT current month but epicEndDate falls under
          // current timeframe month then calculate width
          // based on date of the month
          timelineBarWidth += this.getBarWidthForSingleMonth(
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
          timelineBarWidth += this.getBarWidthForSingleMonth(cellWidth, daysInMonth, daysInMonth);
        }
      }

      // Reduce any offset from total width and round it off.
      return timelineBarWidth - offsetEnd;
    },
  },
};
