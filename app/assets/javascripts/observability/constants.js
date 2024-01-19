import { s__ } from '~/locale';

export const SORTING_OPTIONS = {
  TIMESTAMP_DESC: 'timestamp_desc',
  TIMESTAMP_ASC: 'timestamp_asc',
  DURATION_DESC: 'duration_desc',
  DURATION_ASC: 'duration_asc',
};
Object.freeze(SORTING_OPTIONS);
export const DEFAULT_SORTING_OPTION = SORTING_OPTIONS.TIMESTAMP_DESC;

export const TIME_RANGE_OPTIONS = [
  { value: '5m', title: s__('Observability|Last 5 minutes') },
  { value: '15m', title: s__('Observability|Last 15 minutes') },
  { value: '30m', title: s__('Observability|Last 30 minutes') },
  { value: '1h', title: s__('Observability|Last 1 hour') },
  { value: '4h', title: s__('Observability|Last 4 hours') },
  { value: '12h', title: s__('Observability|Last 12 hours') },
  { value: '24h', title: s__('Observability|Last 24 hours') },
  { value: '7d', title: s__('Observability|Last 7 days') },
  { value: '14d', title: s__('Observability|Last 14 days') },
  { value: '30d', title: s__('Observability|Last 30 days') },
];
Object.freeze(TIME_RANGE_OPTIONS);

const OPERERATOR_LIKE = '=~';
const OPERERATOR_LIKE_TEXT = s__('ObservabilityMetrics|is like');
const OPERERATOR_NOT_LIKE = '!~';
const OPERERATOR_NOT_LIKE_TEXT = s__('ObservabilityMetrics|is not like');

const OPERATORS_LIKE = [{ value: OPERERATOR_LIKE, description: OPERERATOR_LIKE_TEXT }];
const OPERATORS_NOT_LIKE = [{ value: OPERERATOR_NOT_LIKE, description: OPERERATOR_NOT_LIKE_TEXT }];
export const OPERATORS_LIKE_NOT = [...OPERATORS_LIKE, ...OPERATORS_NOT_LIKE];
