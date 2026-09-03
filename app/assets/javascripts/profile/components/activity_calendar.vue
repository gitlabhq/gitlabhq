<script>
import { times, constant, chunk } from 'lodash-es';
import { GlAlert, GlTooltipDirective } from '@gitlab/ui';
import { __, n__, s__, sprintf } from '~/locale';
import { getMonthNames } from '~/lib/utils/datetime/date_format_utility';
import { CONTRIB_LEGENDS, FIRST_DAY_OF_WEEK_CHOICES } from '~/contribution_events/constants';
import AjaxCache from '~/lib/utils/ajax_cache';
import { userCalendarPath } from '~/lib/utils/path_helpers/user';
import {
  getCurrentDateAtOffset,
  nMonthsBefore,
  getDatesInRange,
  localeDateFormat,
  toISODateFormat,
} from '~/lib/utils/datetime_utility';
import { CALENDAR_PERIOD_12_MONTHS } from '../constants';

const MONTH_NAMES = getMonthNames(true);
const DAYS_IN_THE_WEEK = 7;

export default {
  name: 'ActivityCalendar',
  i18n: {
    activityHeading: s__('UserProfile|Activity'),
    calendarLabel: __('Contribution activity calendar'),
    errorAlertTitle: __("There was an error loading the user's activity calendar."),
    retry: __('Retry'),
    calendarHint: __('Issues, merge requests, pushes, and comments.'),
    legendLess: __('Less'),
    legendMore: __('More'),
    monday: s__('DayTitle|M'),
    wednesday: s__('DayTitle|W'),
    friday: s__('DayTitle|F'),
    saturday: s__('DayTitle|S'),
    sunday: s__('DayTitle|S'),
  },
  contribLegends: CONTRIB_LEGENDS,
  components: {
    GlAlert,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    username: { required: true },
    utcOffset: { required: true },
  },
  data() {
    return {
      isLoading: true,
      hasError: false,
      timestamps: {},
    };
  },
  computed: {
    firstDayOfWeek() {
      return gon.first_day_of_week;
    },
    userCalendarPath() {
      return userCalendarPath({ username: this.username, format: 'json' });
    },
    calendarData() {
      const { startDate, endDate } = this.calendarRange;
      const daysInRange = getDatesInRange(startDate, endDate);

      // Empty cells pad the first and last weeks so every day lands in the row
      // matching its day of the week. How far startDate falls into its own week
      // is exactly how many cells precede it.
      const numberOfEmptyDaysToPrepend =
        (startDate.getDay() - this.firstDayOfWeek + DAYS_IN_THE_WEEK) % DAYS_IN_THE_WEEK;

      const numberOfDaysInLastWeek =
        (numberOfEmptyDaysToPrepend + daysInRange.length) % DAYS_IN_THE_WEEK;
      const numberOfEmptyDaysToAppend =
        (DAYS_IN_THE_WEEK - numberOfDaysInLastWeek) % DAYS_IN_THE_WEEK;

      const emptyDaysToPrepend = times(numberOfEmptyDaysToPrepend, constant(null));
      const emptyDaysToAppend = times(numberOfEmptyDaysToAppend, constant(null));

      const daysChunkedIntoWeeks = chunk(
        [...emptyDaysToPrepend, ...daysInRange, ...emptyDaysToAppend],
        DAYS_IN_THE_WEEK,
      );

      const weeksWithComputedMonth = daysChunkedIntoWeeks.map((days) => ({
        days,
        month: days.find((day) => day !== null).getMonth(),
      }));

      const weeksWithComputedMonthLabel = weeksWithComputedMonth.map(
        ({ days, month: currentWeekMonth }, index) => {
          // Skip the first week label if second week is a different month.
          // This prevents labels from rendering next to each other and overlapping.
          if (index === 0) {
            const nextWeekMonth = weeksWithComputedMonth[1].month;
            return {
              days,
              monthLabel: currentWeekMonth === nextWeekMonth ? MONTH_NAMES[currentWeekMonth] : '',
            };
          }

          // Render the month label if the previous week is different.
          // This means the month has changed.
          // This is how we evenly space out the month labels.
          const previousWeekMonth = weeksWithComputedMonth[index - 1].month;
          return {
            days,
            monthLabel: currentWeekMonth !== previousWeekMonth ? MONTH_NAMES[currentWeekMonth] : '',
          };
        },
      );

      return weeksWithComputedMonthLabel;
    },
    systemDate() {
      // Today's calendar date in the profile user's timezone.
      return getCurrentDateAtOffset(this.utcOffset);
    },
    calendarRange() {
      // Always show the full last 12 months; the calendar scrolls horizontally
      // on narrow screens.
      const endDate = this.systemDate;
      const startDate = nMonthsBefore(endDate, CALENDAR_PERIOD_12_MONTHS);

      return { startDate, endDate };
    },
    dayLabels() {
      if (this.firstDayOfWeek === FIRST_DAY_OF_WEEK_CHOICES.monday) {
        return [
          this.$options.i18n.monday,
          null,
          this.$options.i18n.wednesday,
          null,
          this.$options.i18n.friday,
          null,
          this.$options.i18n.sunday,
        ];
      }

      if (this.firstDayOfWeek === FIRST_DAY_OF_WEEK_CHOICES.saturday) {
        return [
          this.$options.i18n.saturday,
          null,
          this.$options.i18n.monday,
          null,
          this.$options.i18n.wednesday,
          null,
          this.$options.i18n.friday,
        ];
      }

      // First day of the week is Sunday
      return [
        null,
        this.$options.i18n.monday,
        null,
        this.$options.i18n.wednesday,
        null,
        this.$options.i18n.friday,
        null,
      ];
    },
  },
  mounted() {
    this.loadActivityCalendar();
  },
  methods: {
    async loadActivityCalendar() {
      this.isLoading = true;
      this.hasError = false;

      try {
        this.timestamps = await AjaxCache.retrieve(this.userCalendarPath);

        // Scroll to the end to show the most recent activity.
        await this.$nextTick();
        this.scrollToEnd();
      } catch {
        this.hasError = true;
      } finally {
        this.isLoading = false;
      }
    },
    dayCount(day) {
      return this.timestamps[toISODateFormat(day)] || 0;
    },
    getLevelFromContributions(count) {
      return CONTRIB_LEGENDS.findLast(({ min }) => count >= min)?.level ?? 0;
    },
    contributionCellClass(day) {
      if (day === null) {
        return null;
      }

      return `user-contribution-graph-cell-${this.getLevelFromContributions(this.dayCount(day))}`;
    },
    getContributionText(day) {
      const count = this.dayCount(day);

      return count > 0 ? n__('%d contribution', '%d contributions', count) : __('No contributions');
    },
    getCellTooltip(day) {
      if (!day) {
        return '';
      }

      const dateText = localeDateFormat.asDateFullWithWeekday.format(day);

      return `${this.getContributionText(day)}<br /><span class="gl-text-neutral-300">${dateText}</span>`;
    },
    getAriaLabel(day) {
      if (!day) {
        return '';
      }

      return sprintf(__('%{contributions} on %{date}'), {
        contributions: this.getContributionText(day),
        date: localeDateFormat.asDateFullWithWeekday.format(day),
      });
    },
    scrollToEnd() {
      const wrapper = this.$refs.calendarWrapper;
      if (wrapper) {
        wrapper.scrollLeft = wrapper.scrollWidth;
      }
    },
  },
};
</script>

<template>
  <div class="gl-mt-4">
    <div class="gl-mb-2 gl-flex gl-items-baseline gl-justify-between">
      <h2 class="gl-heading-3 !gl-mb-3 !gl-mt-2">{{ $options.i18n.activityHeading }}</h2>
    </div>

    <gl-alert
      v-if="hasError"
      :title="$options.i18n.errorAlertTitle"
      :dismissible="false"
      variant="danger"
      :primary-button-text="$options.i18n.retry"
      @primary-action="loadActivityCalendar"
    />
    <div
      v-else
      ref="calendarWrapper"
      class="contrib-calendar-wrapper gl-mx-auto gl-w-full gl-overflow-x-auto gl-pb-5 gl-pr-3"
    >
      <div
        class="contrib-calendar gl-grid gl-w-full gl-min-w-10 gl-grid-flow-col gl-items-stretch gl-gap-1"
        :aria-busy="isLoading"
        data-testid="contrib-calendar"
        role="group"
        :aria-label="$options.i18n.calendarLabel"
      >
        <!-- Top-left corner spacer -->
        <div></div>

        <!-- Day labels: sticky so the weekday gutter stays visible while the
             calendar scrolls horizontally on narrow screens -->
        <div
          v-for="(label, index) in dayLabels"
          :key="`day-${index}`"
          class="gl-sticky gl-left-0 gl-flex gl-w-full gl-items-center gl-justify-center gl-bg-default gl-pr-2 gl-text-xs"
          role="presentation"
          :aria-hidden="label ? null : 'true'"
          data-testid="day-label"
        >
          {{ label }}
        </div>

        <!-- Each week renders one column: its month label slot then its day cells -->
        <template v-for="(week, weekIndex) in calendarData">
          <div
            :key="`month-${weekIndex}`"
            class="gl-w-0 gl-min-w-0 gl-self-center gl-whitespace-nowrap gl-text-left gl-text-sm"
            role="presentation"
            :aria-hidden="week.monthLabel ? null : 'true'"
            data-testid="month-label"
          >
            {{ week.monthLabel }}
          </div>
          <!-- Empty padding cells render as plain divs so they are not
               focusable like the button cells for real days -->
          <component
            :is="day ? 'button' : 'div'"
            v-for="(day, dayIndex) in week.days"
            :key="`cell-${weekIndex}-${dayIndex}`"
            v-gl-tooltip.html="getCellTooltip(day)"
            :type="day ? 'button' : null"
            class="user-contribution-graph-cell gl-aspect-square gl-border-transparent gl-p-0"
            :class="contributionCellClass(day)"
            :style="{ '--contrib-fade-delay': `${(calendarData.length - weekIndex) * 12}ms` }"
            :aria-label="getAriaLabel(day)"
            :aria-hidden="day ? null : 'true'"
            data-testid="user-contrib-cell"
          />
        </template>
      </div>
    </div>
    <div v-if="!hasError" class="gl-mb-0 gl-mt-2 gl-flex gl-items-start gl-justify-between">
      <!-- Legend -->
      <div class="gl-flex gl-items-center gl-gap-2 gl-text-sm">
        <span class="gl-text-sm gl-text-subtle">{{ $options.i18n.legendLess }}</span>
        <div class="gl-flex gl-gap-1">
          <span
            v-for="legend in $options.contribLegends"
            :key="legend.level"
            v-gl-tooltip="legend.title"
            :class="`user-contribution-graph-cell-${legend.level}`"
            class="contrib-legend-cell gl-inline-block gl-h-4 gl-w-4"
            role="img"
            :aria-label="legend.title"
            data-testid="legend-cell"
          ></span>
        </div>
        <span class="gl-text-sm gl-text-subtle">{{ $options.i18n.legendMore }}</span>
      </div>
      <!-- Hint text -->
      <p class="gl-mb-0 gl-text-right gl-text-sm gl-text-subtle">
        {{ $options.i18n.calendarHint }}
      </p>
    </div>
  </div>
</template>
