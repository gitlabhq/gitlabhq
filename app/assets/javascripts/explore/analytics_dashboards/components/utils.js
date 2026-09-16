import { millisecondsPerDay } from '~/lib/utils/datetime_utility';
import {
  DATE_RANGE_OPTIONS,
  DEFAULT_SELECTED_DATE_RANGE_OPTION,
  DATE_RANGE_GRANULARITY_DAILY,
  DATE_RANGE_GRANULARITY_WEEKLY,
  DATE_RANGE_GRANULARITY_MONTHLY,
  DATE_RANGE_GRANULARITY_DAILY_MAX_DAYS,
  DATE_RANGE_GRANULARITY_WEEKLY_MAX_DAYS,
} from './constants';

export const getDateRangeOption = (optionKey) => DATE_RANGE_OPTIONS[optionKey] || null;

export const dateRangeOptionToFilter = ({ startDate, endDate, key }) => ({
  startDate,
  endDate,
  dateRangeOption: key,
});

export const getDateRange = (dateRange, defaultOption = DEFAULT_SELECTED_DATE_RANGE_OPTION) => {
  return DATE_RANGE_OPTIONS[dateRange] || DATE_RANGE_OPTIONS[defaultOption];
};

// The `custom` option carries no dates of its own, so the filter supplies them. Both bounds
// are taken together or neither is: pairing one supplied bound with a default for the other
// inverts the window when the user has only picked the end of a custom range so far.
export const resolveDateRangeFilter = (
  { startDate, endDate, dateRangeOption } = {},
  defaultOption = DEFAULT_SELECTED_DATE_RANGE_OPTION,
) => {
  const option = getDateRange(dateRangeOption, defaultOption);

  if (startDate && endDate) return { ...option, startDate, endDate };

  return option.startDate && option.endDate ? option : getDateRange(defaultOption);
};

// Counted in UTC days because the options build their dates at UTC midnight:
// `getDayDifference` reads local date parts and drops a day west of UTC.
const utcDayDifference = (startDate, endDate) => {
  const utcDay = (date) => Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());

  return (utcDay(endDate) - utcDay(startDate)) / millisecondsPerDay;
};

// Both bounds are inclusive whole days, so a single-day range counts as 1.
export const dateRangeDayCount = ({ startDate, endDate }) =>
  utcDayDifference(startDate, endDate) + 1;

/**
 * Maps a resolved date range to the time bucket granularity a chart should use,
 * so a short range plots days and a long one does not plot hundreds of them.
 *
 * Derived from the range's length rather than the selected option, so a custom
 * range lands on the same granularity as a preset of the same length.
 */
export const dateRangeGranularity = (dateRange) => {
  const days = dateRangeDayCount(dateRange);

  if (days <= DATE_RANGE_GRANULARITY_DAILY_MAX_DAYS) return DATE_RANGE_GRANULARITY_DAILY;
  if (days <= DATE_RANGE_GRANULARITY_WEEKLY_MAX_DAYS) return DATE_RANGE_GRANULARITY_WEEKLY;

  return DATE_RANGE_GRANULARITY_MONTHLY;
};
