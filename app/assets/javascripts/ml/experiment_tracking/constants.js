import { __ } from '~/locale';

export const METRIC_KEY_PREFIX = 'metric.';

export const LIST_KEY_CREATED_AT = 'created_at';

export const BASE_SORT_FIELDS = Object.freeze([
  {
    orderBy: 'name',
    label: __('Name'),
  },
  {
    orderBy: LIST_KEY_CREATED_AT,
    label: __('Created at'),
  },
]);
