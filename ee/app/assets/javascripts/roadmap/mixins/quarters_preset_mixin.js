import { totalDaysInQuarter, dayInQuarter } from '~/lib/utils/datetime_utility';

import { TIMELINE_END_OFFSET_HALF } from '../constants';

export default {
  methods: {
    /**
     * Check if current epic starts within current quarter (timeline cell)
     */
    hasStartDateForQuarter() {
      const quarterStart = this.timeframeItem.range[0];
      const quarterEnd = this.timeframeItem.range[2];

      return this.epic.startDate >= quarterStart && this.epic.startDate <= quarterEnd;
    },
    /**
     * Check if current epic ends within current quarter (timeline cell)
     */
    isTimeframeUnderEndDateForQuarter(timeframeItem, epicEndDate) {
      const quarterEnd = timeframeItem.range[2];

      return epicEndDate <= quarterEnd;
    },
    /**
     * Return timeline bar width for current quarter (timeline cell) based on
     * cellWidth, days in quarter and day of the quarter
     */
    getBarWidthForSingleQuarter(cellWidth, daysInQuarter, day) {
      const dayWidth = cellWidth / daysInQuarter;
      const barWidth = day === daysInQuarter ? cellWidth : dayWidth * day;

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
     *
     * Implementation of this method is identical to
     * MonthsPresetMixin#getTimelineBarStartOffsetForMonths
     */
    getTimelineBarStartOffsetForQuarters() {
      const daysInQuarter = totalDaysInQuarter(this.timeframeItem.range);
      const startDay = dayInQuarter(this.epic.startDate, this.timeframeItem.range);

      if (
        this.epic.startDateOutOfRange ||
        (this.epic.startDateUndefined && this.epic.endDateOutOfRange)
      ) {
        return '';
      } else if (startDay === 1) {
        return 'left: 0;';
      }

      const lastTimeframeItem = this.timeframe[this.timeframe.length - 1].range[2];
      if (
        this.epic.startDate >= this.timeframe[this.timeframe.length - 1].range[0] &&
        this.epic.startDate <= lastTimeframeItem
      ) {
        return `right: ${TIMELINE_END_OFFSET_HALF}px;`;
      }

      return `left: ${startDay / daysInQuarter * 100}%;`;
    },
    /**
     * This method is externally only called when current timeframe cell has timeline
     * bar to show. So when this method is called, we iterate over entire timeframe
     * array starting from current timeframeItem.
     *
     * For eg;
     *  If timeframe range for 6 quarters is;
     *    [2017 Oct Nov Dec], [2018 Jan Feb Mar], [Apr May Jun],
     *    [Jul Aug Sep], [Oct Nov Dec], [2019 Jan Feb Mar]
     *
     *  And if Epic starts in 2017 Dec and ends in 2018 May.
     *
     *  Then this method will iterate over timeframe as;
     *    [2017 Oct Nov Dec] => [2018 Apr May Jun]
     *  And will add up width(see 1.) for timeline bar for each quarter in iteration
     *  based on provided start and end dates.
     *
     *  1. Width from date is calculated by totalWidthCell / totalDaysInQuarter = widthOfSingleDay
     *     and then dayOfQuarter x widthOfSingleDay = totalBarWidth
     *
     * Implementation of this method is identical to
     * MonthsPresetMixin#getTimelineBarWidthForMonths
     */
    getTimelineBarWidthForQuarters() {
      let timelineBarWidth = 0;

      const indexOfCurrentQuarter = this.timeframe.indexOf(this.timeframeItem);
      const cellWidth = this.getCellWidth();
      const offsetEnd = this.getTimelineBarEndOffset();
      const epicStartDate = this.epic.startDate;
      const epicEndDate = this.epic.endDate;

      for (let i = indexOfCurrentQuarter; i < this.timeframe.length; i += 1) {
        const currentQuarter = this.timeframe[i].range;

        if (i === indexOfCurrentQuarter) {
          if (this.isTimeframeUnderEndDateForQuarter(this.timeframe[i], epicEndDate)) {
            timelineBarWidth += this.getBarWidthForSingleQuarter(
              cellWidth,
              totalDaysInQuarter(currentQuarter),
              dayInQuarter(epicEndDate, currentQuarter) -
                dayInQuarter(epicStartDate, currentQuarter) +
                1,
            );
            break;
          } else {
            const daysInQuarter = totalDaysInQuarter(currentQuarter);
            const day = dayInQuarter(epicStartDate, currentQuarter);
            const date = day === 1 ? daysInQuarter : daysInQuarter - day;

            timelineBarWidth += this.getBarWidthForSingleQuarter(
              cellWidth,
              totalDaysInQuarter(currentQuarter),
              date,
            );
          }
        } else if (this.isTimeframeUnderEndDateForQuarter(this.timeframe[i], epicEndDate)) {
          timelineBarWidth += this.getBarWidthForSingleQuarter(
            cellWidth,
            totalDaysInQuarter(currentQuarter),
            dayInQuarter(epicEndDate, currentQuarter),
          );
          break;
        } else {
          const daysInQuarter = totalDaysInQuarter(currentQuarter);
          timelineBarWidth += this.getBarWidthForSingleQuarter(
            cellWidth,
            daysInQuarter,
            daysInQuarter,
          );
        }
      }

      return timelineBarWidth - offsetEnd;
    },
  },
};
