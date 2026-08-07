<script>
import { times, constant, chunk } from 'lodash-es';
import { __, s__ } from '~/locale';
import {
  secondsToMilliseconds,
  nMonthsBefore,
  getDatesInRange,
} from '~/lib/utils/datetime_utility';
import { CALENDAR_PERIOD_12_MONTHS } from '../constants';

export default {
  name: 'ActivityCalendar',
  i18n: {
    activityHeading: s__('UserProfile|Activity'),
    calendarLabel: __('Contribution activity calendar'),
  },
  inject: {
    utcOffset: { required: true },
  },
  computed: {
    firstDayOfWeek() {
      return gon.first_day_of_week;
    },
    calendarData() {
      const daysInTheWeek = 7;
      const { startDate, endDate } = this.calendarRange;
      const days = getDatesInRange(startDate, endDate);

      // Empty cells pad the first and last weeks so every day lands in the row
      // matching its day of the week. How far startDate falls into its own week
      // is exactly how many cells precede it.
      const numberOfEmptyDaysToPrepend =
        (startDate.getDay() - this.firstDayOfWeek + daysInTheWeek) % daysInTheWeek;

      const numberOfDaysInLastWeek = (numberOfEmptyDaysToPrepend + days.length) % daysInTheWeek;
      const numberOfEmptyDaysToAppend = (daysInTheWeek - numberOfDaysInLastWeek) % daysInTheWeek;

      const emptyDaysToPrepend = times(numberOfEmptyDaysToPrepend, constant(null));
      const emptyDaysToAppend = times(numberOfEmptyDaysToAppend, constant(null));

      const daysChunkedIntoWeeks = chunk(
        [...emptyDaysToPrepend, ...days, ...emptyDaysToAppend],
        daysInTheWeek,
      );

      return daysChunkedIntoWeeks;
    },
    systemDate() {
      const nowAtSystemOffset = new Date(Date.now() + secondsToMilliseconds(this.utcOffset));

      return new Date(
        nowAtSystemOffset.getUTCFullYear(),
        nowAtSystemOffset.getUTCMonth(),
        nowAtSystemOffset.getUTCDate(),
      );
    },
    calendarRange() {
      // Always show the full last 12 months; the calendar scrolls horizontally
      // on narrow screens.
      const endDate = this.systemDate;
      const startDate = nMonthsBefore(endDate, CALENDAR_PERIOD_12_MONTHS);

      return { startDate, endDate };
    },
  },
  methods: {
    contributionCellClass(day) {
      if (day === null) {
        return null;
      }

      return 'user-contribution-graph-cell-0';
    },
  },
};
</script>

<template>
  <div class="gl-mt-4">
    <div class="gl-mb-2 gl-flex gl-items-baseline gl-justify-between">
      <h2 class="gl-heading-3 !gl-mb-3 !gl-mt-2">{{ $options.i18n.activityHeading }}</h2>
    </div>

    <div class="contrib-calendar-wrapper gl-mx-auto gl-w-full gl-overflow-x-auto gl-pb-5 gl-pr-3">
      <div
        class="gl-grid gl-w-full gl-min-w-10 gl-grid-flow-col gl-grid-rows-7 gl-items-stretch gl-gap-1"
        data-testid="contrib-calendar"
        role="group"
        :aria-label="$options.i18n.calendarLabel"
      >
        <template v-for="(week, weekIndex) in calendarData">
          <div
            v-for="(day, dayIndex) in week"
            :key="`cell-${weekIndex}-${dayIndex}`"
            class="user-contribution-graph-cell gl-aspect-square gl-border-transparent"
            :class="contributionCellClass(day)"
            :aria-hidden="day ? null : 'true'"
            data-testid="user-contrib-cell"
          ></div>
        </template>
      </div>
    </div>
  </div>
</template>
