import {
  OVERVIEW_CALENDAR_BREAKPOINT,
  CALENDAR_PERIOD_6_MONTHS,
  CALENDAR_PERIOD_12_MONTHS,
} from './constants';

export const getVisibleCalendarPeriod = (calendarContainer) => {
  const { width } = calendarContainer.getBoundingClientRect();

  return width < OVERVIEW_CALENDAR_BREAKPOINT
    ? CALENDAR_PERIOD_6_MONTHS
    : CALENDAR_PERIOD_12_MONTHS;
};
