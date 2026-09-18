import { queryToObject } from '~/lib/utils/url_utility';
import {
  DATE_ONLY_REGEX,
  getStartOfDay,
  isValidDate,
  millisecondsPerDay,
  newDate,
  setUTCTime,
  toISODateFormat,
} from '~/lib/utils/datetime_utility';
import {
  DATE_RANGE_GRANULARITY_DAILY,
  DATE_RANGE_GRANULARITY_DAILY_MAX_DAYS,
  DATE_RANGE_GRANULARITY_MONTHLY,
  DATE_RANGE_GRANULARITY_WEEKLY,
  DATE_RANGE_GRANULARITY_WEEKLY_MAX_DAYS,
  DATE_RANGE_OPTION_CUSTOM,
  DATE_RANGE_OPTIONS,
  DATE_RANGE_QUERY_NAME,
  DEFAULT_DATE_RANGE_OPTIONS,
  DEFAULT_SELECTED_DATE_RANGE_OPTION,
  END_DATE_QUERY_NAME,
  START_DATE_QUERY_NAME,
  TODAY,
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

// The query string names the calendar day the picker showed, so it is read back at local
// midnight, the time the picker works in.
const dateFromQuery = (value) => (DATE_ONLY_REGEX.test(value) ? newDate(value) : null);

// The URL is the source of truth for the date range on load, so a reloaded or shared link
// restores the window its sender saw. Returns null when the query string names no usable
// range, leaving the caller's own default in place.
export const dateRangeFilterFromQuery = (
  queryString,
  { options = DEFAULT_DATE_RANGE_OPTIONS, daysLimit = 0 } = {},
) => {
  const query = queryToObject(queryString);
  const dateRangeOption = query[DATE_RANGE_QUERY_NAME];

  // An option the dashboard does not offer is ignored rather than honoured.
  if (!options.includes(dateRangeOption)) return null;

  if (dateRangeOption !== DATE_RANGE_OPTION_CUSTOM) {
    return dateRangeOptionToFilter(getDateRangeOption(dateRangeOption));
  }

  const startDate = dateFromQuery(query[START_DATE_QUERY_NAME]);
  const endDate = dateFromQuery(query[END_DATE_QUERY_NAME]);

  // Ignore invalid dates or date range
  if (!isValidDate(startDate) || !isValidDate(endDate) || startDate > endDate) return null;

  // Ignore an out of bounds end date
  if (endDate > getStartOfDay(TODAY)) return null;

  // Ignore a date range that exceeds the limit
  if (daysLimit && dateRangeDayCount({ startDate, endDate }) > daysLimit) return null;

  return { dateRangeOption, startDate, endDate };
};

export const dateRangeFilterToQueryParams = ({ dateRangeOption, startDate, endDate } = {}) => {
  const hasCustomRange =
    dateRangeOption === DATE_RANGE_OPTION_CUSTOM && isValidDate(startDate) && isValidDate(endDate);

  return {
    [DATE_RANGE_QUERY_NAME]: dateRangeOption ?? null,

    // Written using local time, to be consistent with the date picker.
    [START_DATE_QUERY_NAME]: hasCustomRange ? toISODateFormat(startDate) : null,
    [END_DATE_QUERY_NAME]: hasCustomRange ? toISODateFormat(endDate) : null,
  };
};

// Keeps the day and drops the time, so a local midnight becomes the same calendar day at UTC
// midnight rather than the day either side of it.
const toUtcDay = (date) => (date ? setUTCTime(toISODateFormat(date)) : null);

// The picker and the query string both work in local time but the panels query whole UTC
// days, so a range is converted when it crosses between them. Only applies to custom ranges
// as the preset options define their own ranges.
export const dateRangeFilterToUtc = (filter = {}) => {
  if (filter.dateRangeOption !== DATE_RANGE_OPTION_CUSTOM) return filter;

  return {
    ...filter,
    startDate: toUtcDay(filter.startDate),
    endDate: toUtcDay(filter.endDate),
  };
};
