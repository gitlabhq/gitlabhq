import { __, sprintf } from '~/locale';
import { nDaysBefore, getStartOfDay } from '~/lib/utils/datetime_utility';

// Compute all relative dates based on the _beginning_ of today.
// We use this date as the end date for the charts. This causes
// the current date to be the last day included in the graph.
export const TODAY = getStartOfDay(new Date(), { utc: true });
export const SEVEN_DAYS_AGO = nDaysBefore(TODAY, 7, { utc: true });

export const DATE_RANGE_OPTION_TODAY = 'today';
export const DATE_RANGE_OPTION_LAST_7_DAYS = '7d';
export const DATE_RANGE_OPTION_LAST_30_DAYS = '30d';
export const DATE_RANGE_OPTION_LAST_60_DAYS = '60d';
export const DATE_RANGE_OPTION_LAST_90_DAYS = '90d';
export const DATE_RANGE_OPTION_LAST_180_DAYS = '180d';
export const DATE_RANGE_OPTION_LAST_365_DAYS = '365d';
export const DATE_RANGE_OPTION_CUSTOM = 'custom';

export const DEFAULT_DATE_RANGE_OPTIONS = [
  DATE_RANGE_OPTION_TODAY,
  DATE_RANGE_OPTION_LAST_7_DAYS,
  DATE_RANGE_OPTION_LAST_30_DAYS,
  DATE_RANGE_OPTION_LAST_60_DAYS,
  DATE_RANGE_OPTION_LAST_90_DAYS,
  DATE_RANGE_OPTION_LAST_180_DAYS,
  DATE_RANGE_OPTION_LAST_365_DAYS,
  DATE_RANGE_OPTION_CUSTOM,
];

export const DEFAULT_SELECTED_DATE_RANGE_OPTION = DATE_RANGE_OPTION_LAST_7_DAYS;

/**
 * The default options to display in the date_range_filter.
 *
 * Each options consists of:
 *
 * key - The key used to select the option and sync with the URL
 * text - Text to display in the dropdown item
 * startDate - Optional, the start date to set
 * endDate - Optional, the end date to set
 * previousRange - Optional, Gives the preceding date range (Ex. for last 7 days (0-7), would return days 8-15)
 * previousRange.startDate - Optional, start date of the preceding time period
 * previousRange.endDate - Optional, end date of the preceding time period
 * showDateRangePicker - Optional, show the date range picker component and uses
 *                       it to set the date.
 */
export const DATE_RANGE_OPTIONS = {
  [DATE_RANGE_OPTION_LAST_365_DAYS]: {
    key: DATE_RANGE_OPTION_LAST_365_DAYS,
    text: sprintf(__('Last %{days} days'), { days: 365 }),
    startDate: nDaysBefore(TODAY, 365, { utc: true }),
    endDate: TODAY,
    previousRange: {
      startDate: nDaysBefore(TODAY, 365 + 366, { utc: true }),
      endDate: nDaysBefore(TODAY, 366, { utc: true }),
    },
  },
  [DATE_RANGE_OPTION_LAST_180_DAYS]: {
    key: DATE_RANGE_OPTION_LAST_180_DAYS,
    text: sprintf(__('Last %{days} days'), { days: 180 }),
    startDate: nDaysBefore(TODAY, 180, { utc: true }),
    endDate: TODAY,
    previousRange: {
      startDate: nDaysBefore(TODAY, 180 + 181, { utc: true }),
      endDate: nDaysBefore(TODAY, 181, { utc: true }),
    },
  },
  [DATE_RANGE_OPTION_LAST_90_DAYS]: {
    key: DATE_RANGE_OPTION_LAST_90_DAYS,
    text: sprintf(__('Last %{days} days'), { days: 90 }),
    startDate: nDaysBefore(TODAY, 90, { utc: true }),
    endDate: TODAY,
    previousRange: {
      startDate: nDaysBefore(TODAY, 90 + 91, { utc: true }),
      endDate: nDaysBefore(TODAY, 91, { utc: true }),
    },
  },
  [DATE_RANGE_OPTION_LAST_60_DAYS]: {
    key: DATE_RANGE_OPTION_LAST_60_DAYS,
    text: sprintf(__('Last %{days} days'), { days: 60 }),
    startDate: nDaysBefore(TODAY, 60, { utc: true }),
    endDate: TODAY,
    previousRange: {
      startDate: nDaysBefore(TODAY, 60 + 61, { utc: true }),
      endDate: nDaysBefore(TODAY, 61, { utc: true }),
    },
  },
  [DATE_RANGE_OPTION_LAST_30_DAYS]: {
    key: DATE_RANGE_OPTION_LAST_30_DAYS,
    text: sprintf(__('Last %{days} days'), { days: 30 }),
    startDate: nDaysBefore(TODAY, 30, { utc: true }),
    endDate: TODAY,
    previousRange: {
      startDate: nDaysBefore(TODAY, 30 + 31, { utc: true }),
      endDate: nDaysBefore(TODAY, 31, { utc: true }),
    },
  },
  [DATE_RANGE_OPTION_LAST_7_DAYS]: {
    key: DATE_RANGE_OPTION_LAST_7_DAYS,
    text: sprintf(__('Last %{days} days'), { days: 7 }),
    startDate: SEVEN_DAYS_AGO,
    endDate: TODAY,
    previousRange: {
      startDate: nDaysBefore(TODAY, 7 + 8, { utc: true }),
      endDate: nDaysBefore(TODAY, 8, { utc: true }),
    },
  },
  [DATE_RANGE_OPTION_TODAY]: {
    key: DATE_RANGE_OPTION_TODAY,
    text: __('Today'),
    startDate: TODAY,
    endDate: TODAY,
    previousRange: {
      startDate: nDaysBefore(TODAY, 1, { utc: true }),
      endDate: nDaysBefore(TODAY, 1, { utc: true }),
    },
  },
  [DATE_RANGE_OPTION_CUSTOM]: {
    key: DATE_RANGE_OPTION_CUSTOM,
    text: __('Custom range'),
    showDateRangePicker: true,
  },
};

export const DATE_RANGE_OPTION_KEYS = Object.keys(DATE_RANGE_OPTIONS);

export const PROJECT_FILTER_QUERY_NAME = 'projects';
export const GROUP_FILTER_QUERY_NAME = 'groups';
