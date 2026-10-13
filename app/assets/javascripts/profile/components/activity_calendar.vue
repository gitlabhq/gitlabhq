<script>
import { times, constant, chunk } from 'lodash-es';
import { GlAlert, GlButton, GlLink, GlEmptyState, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { __, n__, s__, sprintf } from '~/locale';
import { getMonthNames } from '~/lib/utils/datetime/date_format_utility';
import { CONTRIB_LEGENDS, FIRST_DAY_OF_WEEK_CHOICES } from '~/contribution_events/constants';
import AjaxCache from '~/lib/utils/ajax_cache';
import axios from '~/lib/utils/axios_utils';
import {
  ARROW_LEFT_KEY,
  ARROW_RIGHT_KEY,
  ARROW_UP_KEY,
  ARROW_DOWN_KEY,
  HOME_KEY,
  END_KEY,
  PAGE_UP_KEY,
  PAGE_DOWN_KEY,
} from '~/lib/utils/keys';
import { userCalendarPath } from '~/lib/utils/path_helpers/user';
import {
  getCurrentDateAtOffset,
  nMonthsBefore,
  getDatesInRange,
  localeDateFormat,
  toISODateFormat,
} from '~/lib/utils/datetime_utility';
import ContributionEvents from '~/contribution_events/components/contribution_events.vue';
import { CALENDAR_PERIOD_12_MONTHS } from '../constants';
import ActivitySkeletonLoader from './activity_skeleton_loader.vue';

const MONTH_NAMES = getMonthNames(true);
const DAYS_IN_THE_WEEK = 7;
const FIRST_DAY_OF_WEEK_INDEX = 0;
const LAST_DAY_OF_WEEK_INDEX = 6;

export default {
  name: 'ActivityCalendar',
  i18n: {
    activityHeading: s__('UserProfile|Activity'),
    calendarLabel: __('Contribution activity calendar'),
    errorAlertTitle: __("There was an error loading the user's activity calendar."),
    activitiesErrorTitle: __('There was an error loading activities.'),
    retry: __('Retry'),
    calendarHint: __('Issues, merge requests, pushes, and comments.'),
    legendLess: __('Less'),
    legendMore: __('More'),
    monday: s__('DayTitle|M'),
    wednesday: s__('DayTitle|W'),
    friday: s__('DayTitle|F'),
    saturday: s__('DayTitle|S'),
    sunday: s__('DayTitle|S'),
    viewAll: s__('UserProfile|View all'),
    viewAllActivityLabel: __('View all activity'),
    noContributions: __('No contributions were found.'),
    loadMore: __('Load more'),
    emptyStateOwnTitle: s__('UserProfile|No activities found'),
    emptyStateVisitorTitle: __('No activities found'),
    emptyStateDescription: s__(
      'UserProfile|Join or create a group to start contributing by commenting on issues or submitting merge requests!',
    ),
    emptyStatePrimaryButton: __('New group'),
    emptyStateSecondaryButton: __('Explore groups'),
  },
  contribLegends: CONTRIB_LEGENDS,
  components: {
    GlAlert,
    GlButton,
    GlLink,
    GlEmptyState,
    GlSprintf,
    ContributionEvents,
    ActivitySkeletonLoader,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    username: {},
    utcOffset: {},
    userCalendarActivitiesPath: {},
    userActivityPath: { default: null },
    viewAllActivityPath: { default: null },
    isCurrentUserProfile: { default: false },
    emptyStateSvgPath: { default: '' },
    newGroupPath: { default: '' },
    exploreGroupsPath: { default: '' },
  },
  data() {
    return {
      isLoading: true,
      hasError: false,
      timestamps: {},
      focusedCell: { weekIndex: 0, dayIndex: 0 },
      selectedDate: null,
      selectedDateFormatted: null,
      activities: [],
      activitiesLoading: false,
      activitiesLoadingMore: false,
      activitiesError: false,
      initialActivitiesPageSize: 15,
      activitiesPageSize: 50,
      activitiesOffset: 0,
      hasMoreActivities: true,
      hasActivity: false,
      activitiesLoaded: false,
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
    calendarDataForKeyboardNavigation() {
      return this.calendarData.flatMap((week, weekIndex) => {
        return week.days.map((day, dayIndex) => ({ weekIndex, dayIndex, day }));
      });
    },
    firstTabableCell() {
      return this.calendarDataForKeyboardNavigation.find(({ day }) => day !== null);
    },
    lastAvailableCell() {
      return this.calendarDataForKeyboardNavigation.findLast(({ day }) => day !== null);
    },
    horizontalNavigationCells() {
      // Real cells in visual row order: the same day across all weeks, then
      // the next day's row. Horizontal arrow steps walk this sequence.
      return this.calendarDataForKeyboardNavigation
        .filter(({ day }) => day !== null)
        .sort((a, b) => a.dayIndex - b.dayIndex || a.weekIndex - b.weekIndex);
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
    activityHeadingLabel() {
      return this.selectedDateFormatted;
    },
    selectedDayContributions() {
      return this.selectedDate ? this.timestamps[this.selectedDate] || 0 : 0;
    },
    activityHeadingMessage() {
      // Substitute the count here (named placeholders can't mix with %d) and
      // leave %{label} for GlSprintf to render the bold label.
      return sprintf(
        n__(
          '%{count} Contribution for %{label}',
          '%{count} Contributions for %{label}',
          this.selectedDayContributions,
        ),
        { count: this.selectedDayContributions },
      );
    },
    emptyStateTitle() {
      return this.isCurrentUserProfile
        ? this.$options.i18n.emptyStateOwnTitle
        : this.$options.i18n.emptyStateVisitorTitle;
    },
    currentPageSize() {
      // The default rolling "Last 12 months" feed pages in smaller chunks; a
      // selected day uses the larger page size.
      return this.selectedDate ? this.activitiesPageSize : this.initialActivitiesPageSize;
    },
  },
  created() {
    // The grid renders while the fetch is in flight, so the roving tabindex
    // must point at a real (non-padding) cell before the data arrives.
    this.initializeFocusedCell();
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

        // Load the general activity feed by default when it is enabled.
        if (this.userActivityPath) {
          this.loadGeneralActivities();
        }
      } catch {
        this.hasError = true;
      } finally {
        this.isLoading = false;
      }
    },
    toISODateFormat(day) {
      return toISODateFormat(day);
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
        // null omits the aria-label attribute entirely on empty padding cells
        return null;
      }

      return sprintf(__('%{contributions} on %{date}'), {
        contributions: this.getContributionText(day),
        date: localeDateFormat.asDateFullWithWeekday.format(day),
      });
    },
    getCellId(weekIndex, dayIndex) {
      return `calendar-cell-${weekIndex}-${dayIndex}`;
    },
    getCellTabIndex(weekIndex, dayIndex) {
      if (this.focusedCell.weekIndex === weekIndex && this.focusedCell.dayIndex === dayIndex) {
        return '0';
      }

      return '-1';
    },
    handleKeyDown(event, weekIndex, dayIndex) {
      const { key } = event;
      let handled = false;

      switch (key) {
        case ARROW_LEFT_KEY:
          // Previous week (wraps to the previous row's last cell)
          this.moveHorizontal(weekIndex, dayIndex, -1);
          handled = true;
          break;
        case ARROW_RIGHT_KEY:
          // Next week (wraps to the next row's first cell)
          this.moveHorizontal(weekIndex, dayIndex, 1);
          handled = true;
          break;
        case ARROW_UP_KEY:
          // Previous day (wraps to the previous week's last day)
          this.moveVertical(weekIndex, dayIndex, -1);
          handled = true;
          break;
        case ARROW_DOWN_KEY:
          // Next day (wraps to the next week's first day)
          this.moveVertical(weekIndex, dayIndex, 1);
          handled = true;
          break;
        case HOME_KEY:
          // Move to the first available day of the current week
          this.focusFirstDayOfWeek(weekIndex);
          handled = true;
          break;
        case END_KEY:
          // Move to the last available day of the current week
          this.focusLastDayOfWeek(weekIndex);
          handled = true;
          break;
        case PAGE_UP_KEY:
          // Move to same day, 4 weeks earlier
          this.moveHorizontal(weekIndex, dayIndex, -4);
          handled = true;
          break;
        case PAGE_DOWN_KEY:
          // Move to same day, 4 weeks later
          this.moveHorizontal(weekIndex, dayIndex, 4);
          handled = true;
          break;
        default:
          break;
      }

      if (handled) {
        event.preventDefault();
      }
    },
    moveHorizontal(weekIndex, dayIndex, delta) {
      if (Math.abs(delta) > 1) {
        const rowCells = this.horizontalNavigationCells.filter(
          (cell) => cell.dayIndex === dayIndex,
        );
        const firstWeekOfRow = rowCells[0].weekIndex;
        const lastWeekOfRow = rowCells[rowCells.length - 1].weekIndex;
        const targetWeek = Math.min(Math.max(weekIndex + delta, firstWeekOfRow), lastWeekOfRow);

        this.setFocusedCell(targetWeek, dayIndex);

        return;
      }

      const cells = this.horizontalNavigationCells;
      const currentIndex = cells.findIndex(
        (cell) => cell.weekIndex === weekIndex && cell.dayIndex === dayIndex,
      );
      const foundCell = cells[currentIndex + delta];

      if (!foundCell) {
        return;
      }

      this.setFocusedCell(foundCell.weekIndex, foundCell.dayIndex);
    },
    moveVertical(weekIndex, dayIndex, delta) {
      let targetWeek = weekIndex;
      let targetDay = dayIndex + delta;

      // Wrap across week boundaries (columns).
      if (targetDay > LAST_DAY_OF_WEEK_INDEX) {
        targetWeek += 1;
        targetDay = FIRST_DAY_OF_WEEK_INDEX;
      } else if (targetDay < FIRST_DAY_OF_WEEK_INDEX) {
        targetWeek -= 1;
        targetDay = LAST_DAY_OF_WEEK_INDEX;
      }

      const foundCell = this.calendarDataForKeyboardNavigation.find(
        (cell) => cell.weekIndex === targetWeek && cell.dayIndex === targetDay && cell.day !== null,
      );

      // Only the calendar's very first/last day has no vertical neighbor
      // (padding only pads the edge weeks), so wrap to the opposite end.
      if (!foundCell) {
        const cell = delta > 0 ? this.firstTabableCell : this.lastAvailableCell;
        this.setFocusedCell(cell.weekIndex, cell.dayIndex);

        return;
      }

      this.setFocusedCell(foundCell.weekIndex, foundCell.dayIndex);
    },
    focusFirstDayOfWeek(weekIndex) {
      const foundCell = this.calendarDataForKeyboardNavigation.find(
        (cell) =>
          cell.weekIndex === weekIndex &&
          cell.dayIndex >= FIRST_DAY_OF_WEEK_INDEX &&
          cell.day !== null,
      );

      if (!foundCell) {
        return;
      }

      this.setFocusedCell(foundCell.weekIndex, foundCell.dayIndex);
    },
    focusLastDayOfWeek(weekIndex) {
      const foundCell = this.calendarDataForKeyboardNavigation.findLast(
        (cell) =>
          cell.weekIndex === weekIndex &&
          cell.dayIndex <= LAST_DAY_OF_WEEK_INDEX &&
          cell.day !== null,
      );

      if (!foundCell) {
        return;
      }

      this.setFocusedCell(foundCell.weekIndex, foundCell.dayIndex);
    },
    setFocusedCell(weekIndex, dayIndex) {
      this.focusedCell = { weekIndex, dayIndex };

      this.$nextTick(() => {
        // Scoped to the component root so duplicate ids from a second mount
        // cannot steal the focus target.
        const element = this.$el.querySelector(`#${this.getCellId(weekIndex, dayIndex)}`);
        if (element) {
          element.focus();
        }
      });
    },
    findCellByDate(dateString) {
      return this.calendarDataForKeyboardNavigation.find(
        ({ day }) => day && toISODateFormat(day) === dateString,
      );
    },
    initializeFocusedCell() {
      // The tab-stop follows the active day when one is selected, so tabbing
      // into the calendar lands on it; otherwise it defaults to the first cell.
      // Direct assignment: setFocusedCell would move DOM focus into the
      // calendar, which must only happen for user-initiated navigation.
      const activeCell = this.selectedDate && this.findCellByDate(this.selectedDate);
      const { weekIndex, dayIndex } = activeCell || this.firstTabableCell;
      this.focusedCell = { weekIndex, dayIndex };
    },
    scrollToEnd() {
      const wrapper = this.$refs.calendarWrapper;
      if (wrapper) {
        wrapper.scrollLeft = wrapper.scrollWidth;
      }
    },
    async handleClickDay(day, weekIndex, dayIndex) {
      // Ignore clicks while the calendar is still rendering its placeholder.
      if (this.isLoading || !this.userActivityPath) {
        return;
      }

      const dateString = toISODateFormat(day);

      if (this.selectedDate === dateString) {
        // Deselect the day and show the general activity feed.
        this.selectedDate = null;
        this.selectedDateFormatted = null;
        this.activitiesOffset = 0;
        this.activities = [];
        await this.loadGeneralActivities();
      } else {
        // Select the day and show its activities. The clicked button is already
        // focused, so keep the roving tab-stop on it via a direct assignment
        // (setFocusedCell would re-run focus() unnecessarily).
        this.selectedDate = dateString;
        this.selectedDateFormatted = localeDateFormat.asDateFullWithWeekday.format(day);
        this.focusedCell = { weekIndex, dayIndex };
        this.activitiesOffset = 0;
        this.activities = [];
        await this.loadActivities(dateString);
      }
    },
    async loadMoreActivities() {
      if (this.selectedDate) {
        await this.loadActivities(this.selectedDate, true);
      } else {
        await this.loadGeneralActivities(true);
      }
    },
    async loadActivities(dateString, append = false) {
      if (append) {
        this.activitiesLoadingMore = true;
      } else {
        this.activitiesLoading = true;
        this.activities = [];
      }
      this.activitiesError = false;

      // "Load more" always pages by activitiesPageSize; the initial load uses
      // the (possibly smaller) page size for the current view.
      const limit = append ? this.activitiesPageSize : this.currentPageSize;
      const offset = append ? this.activitiesOffset : 0;

      try {
        const { data } = await axios.get(this.userCalendarActivitiesPath, {
          params: { date: dateString, limit, offset },
          headers: { Accept: 'application/json' },
        });

        const newEvents = data || [];
        this.activities = append ? [...this.activities, ...newEvents] : newEvents;
        this.activitiesOffset = offset + limit;
        this.hasMoreActivities = newEvents.length >= limit;
      } catch {
        this.activitiesError = true;
      } finally {
        this.activitiesLoading = false;
        this.activitiesLoadingMore = false;
      }
    },
    async loadGeneralActivities(append = false) {
      if (append) {
        this.activitiesLoadingMore = true;
      } else {
        this.activitiesLoading = true;
        this.activities = [];
      }
      this.activitiesError = false;

      const limit = append ? this.activitiesPageSize : this.currentPageSize;
      const offset = append ? this.activitiesOffset : 0;

      try {
        const { data } = await axios.get(this.userActivityPath, {
          params: { type: 'raw', limit, offset },
          headers: { Accept: 'application/json' },
        });

        const newEvents = data || [];
        this.activities = append ? [...this.activities, ...newEvents] : newEvents;
        this.activitiesOffset = offset + limit;
        this.hasMoreActivities = newEvents.length >= limit;

        // The general (no day selected) feed reflects whether the user has any
        // activity at all, so use it to drive the "View all" link.
        if (!append) {
          this.hasActivity = this.activities.length > 0;
          this.activitiesLoaded = true;
        }
      } catch {
        this.activitiesError = true;
      } finally {
        this.activitiesLoading = false;
        this.activitiesLoadingMore = false;
      }
    },
  },
};
</script>

<template>
  <div class="gl-mt-4">
    <div class="gl-mb-2 gl-flex gl-items-baseline gl-justify-between">
      <h2 class="gl-heading-3 !gl-mb-3 !gl-mt-2">{{ $options.i18n.activityHeading }}</h2>
      <gl-link
        v-if="userActivityPath"
        :href="viewAllActivityPath"
        :aria-label="$options.i18n.viewAllActivityLabel"
        :class="{ 'gl-hidden': !hasActivity }"
        data-testid="view-all"
      >
        {{ $options.i18n.viewAll }}
      </gl-link>
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
            :id="getCellId(weekIndex, dayIndex)"
            :key="`cell-${weekIndex}-${dayIndex}`"
            v-gl-tooltip.html="getCellTooltip(day)"
            :type="day ? 'button' : null"
            class="user-contribution-graph-cell gl-aspect-square gl-border-transparent gl-p-0"
            :class="[
              contributionCellClass(day),
              { 'is-active': day && selectedDate === toISODateFormat(day) },
            ]"
            :style="{ '--contrib-fade-delay': `${(calendarData.length - weekIndex) * 12}ms` }"
            :aria-label="getAriaLabel(day)"
            :aria-hidden="day ? null : 'true'"
            :tabindex="getCellTabIndex(weekIndex, dayIndex)"
            data-testid="user-contrib-cell"
            @click="day && handleClickDay(day, weekIndex, dayIndex)"
            @keydown="handleKeyDown($event, weekIndex, dayIndex)"
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

    <!-- Activity feed (only shown when the Vue activity feed is enabled) -->
    <div
      v-if="
        userActivityPath &&
        (selectedDate || activities.length > 0 || activitiesLoading || activitiesError)
      "
      class="gl-my-5"
      data-testid="calendar-activities"
    >
      <h3 v-if="selectedDate" class="gl-heading-4">
        <gl-sprintf :message="activityHeadingMessage">
          <template #label>
            <strong>{{ activityHeadingLabel }}</strong>
          </template>
        </gl-sprintf>
      </h3>

      <!-- Initial loading: skeleton entries mimicking the activity list -->
      <activity-skeleton-loader
        v-if="activitiesLoading && activities.length === 0"
        class="-gl-mt-3"
      />

      <!-- Error state -->
      <gl-alert
        v-else-if="activitiesError"
        :title="$options.i18n.activitiesErrorTitle"
        :dismissible="false"
        variant="danger"
        :primary-button-text="$options.i18n.retry"
        @primary-action="selectedDate ? loadActivities(selectedDate) : loadGeneralActivities()"
      />

      <!-- Activities list (stays visible while loading more) -->
      <div v-else-if="activities.length > 0">
        <contribution-events :events="activities" variant="default" class="gl-mb-0" />

        <!-- Loading more indicator -->
        <activity-skeleton-loader v-if="activitiesLoadingMore" />

        <!-- Load more button -->
        <div v-else-if="hasMoreActivities" class="gl-text-center">
          <gl-button @click="loadMoreActivities">
            {{ $options.i18n.loadMore }}
          </gl-button>
        </div>
      </div>

      <!-- Selected day with no contributions -->
      <p v-else class="gl-mb-0">
        {{ $options.i18n.noContributions }}
      </p>
    </div>

    <!-- Empty state: the user has no activity at all -->
    <gl-empty-state
      v-else-if="userActivityPath && activitiesLoaded && !hasActivity"
      :svg-path="emptyStateSvgPath"
      :title="emptyStateTitle"
      :primary-button-text="isCurrentUserProfile ? $options.i18n.emptyStatePrimaryButton : null"
      :primary-button-link="isCurrentUserProfile ? newGroupPath : null"
      :secondary-button-text="isCurrentUserProfile ? $options.i18n.emptyStateSecondaryButton : null"
      :secondary-button-link="isCurrentUserProfile ? exploreGroupsPath : null"
      data-testid="activity-empty-state"
    >
      <template v-if="isCurrentUserProfile" #description>
        {{ $options.i18n.emptyStateDescription }}
      </template>
    </gl-empty-state>
  </div>
</template>
