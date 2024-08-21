import { s__ } from '~/locale';

export const SORTING_OPTIONS = {
  TIMESTAMP_DESC: 'timestamp_desc',
  TIMESTAMP_ASC: 'timestamp_asc',
  DURATION_DESC: 'duration_desc',
  DURATION_ASC: 'duration_asc',
};
Object.freeze(SORTING_OPTIONS);
export const DEFAULT_SORTING_OPTION = SORTING_OPTIONS.TIMESTAMP_DESC;

export const TIME_RANGE_OPTIONS_VALUES = {
  FIVE_MIN: '5m',
  FIFTEEN_MIN: '15m',
  THIRTY_MIN: '30m',
  ONE_HOUR: '1h',
  FOUR_HOURS: '4h',
  TWELVE_HOURS: '12h',
  ONE_DAY: '24h',
  ONE_WEEK: '7d',
  TWO_WEEKS: '14d',
  ONE_MONTH: '30d',
};

export const TIME_RANGE_OPTIONS = [
  { value: TIME_RANGE_OPTIONS_VALUES.FIVE_MIN, title: s__('Observability|Last 5 minutes') },
  { value: TIME_RANGE_OPTIONS_VALUES.FIFTEEN_MIN, title: s__('Observability|Last 15 minutes') },
  { value: TIME_RANGE_OPTIONS_VALUES.THIRTY_MIN, title: s__('Observability|Last 30 minutes') },
  { value: TIME_RANGE_OPTIONS_VALUES.ONE_HOUR, title: s__('Observability|Last 1 hour') },
  { value: TIME_RANGE_OPTIONS_VALUES.FOUR_HOURS, title: s__('Observability|Last 4 hours') },
  { value: TIME_RANGE_OPTIONS_VALUES.TWELVE_HOURS, title: s__('Observability|Last 12 hours') },
  { value: TIME_RANGE_OPTIONS_VALUES.ONE_DAY, title: s__('Observability|Last 24 hours') },
  { value: TIME_RANGE_OPTIONS_VALUES.ONE_WEEK, title: s__('Observability|Last 7 days') },
  { value: TIME_RANGE_OPTIONS_VALUES.TWO_WEEKS, title: s__('Observability|Last 14 days') },
  { value: TIME_RANGE_OPTIONS_VALUES.ONE_MONTH, title: s__('Observability|Last 30 days') },
];
Object.freeze(TIME_RANGE_OPTIONS);

export const OPERERATOR_LIKE = '=~';
const OPERERATOR_LIKE_TEXT = s__('ObservabilityMetrics|is like');
export const OPERERATOR_NOT_LIKE = '!~';
const OPERERATOR_NOT_LIKE_TEXT = s__('ObservabilityMetrics|is not like');

const OPERATORS_LIKE = [{ value: OPERERATOR_LIKE, description: OPERERATOR_LIKE_TEXT }];
const OPERATORS_NOT_LIKE = [{ value: OPERERATOR_NOT_LIKE, description: OPERERATOR_NOT_LIKE_TEXT }];
export const OPERATORS_LIKE_NOT = [...OPERATORS_LIKE, ...OPERATORS_NOT_LIKE];

export const CUSTOM_DATE_RANGE_OPTION = 'custom';
export const DATE_RANGE_QUERY_KEY = 'date_range';
export const DATE_RANGE_START_QUERY_KEY = 'date_start';
export const DATE_RANGE_END_QUERY_KEY = 'date_end';
export const TIMESTAMP_QUERY_KEY = 'timestamp';

export const FILTERED_SEARCH_TERM_QUERY_KEY = 'search';

export const FULL_DATE_TIME_FORMAT = `mmm dd yyyy HH:MM:ss.l Z`;
export const SHORT_DATE_TIME_FORMAT = `mmm dd yyyy HH:MM:ss Z`;

export const ISSUE_PATH_ID_SEPARATOR = '#';
