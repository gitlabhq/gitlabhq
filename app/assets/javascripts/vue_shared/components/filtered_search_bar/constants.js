/* eslint-disable @gitlab/require-i18n-strings */
import { __ } from '~/locale';

export const DEBOUNCE_DELAY = 200;

export const FILTER_NONE = 'None';
export const FILTER_ANY = 'Any';
export const FILTER_CURRENT = 'Current';

export const DEFAULT_LABEL_NONE = { value: FILTER_NONE, text: __(FILTER_NONE) };
export const DEFAULT_LABEL_ANY = { value: FILTER_ANY, text: __(FILTER_ANY) };
export const DEFAULT_NONE_ANY = [DEFAULT_LABEL_NONE, DEFAULT_LABEL_ANY];

export const DEFAULT_ITERATIONS = DEFAULT_NONE_ANY.concat([
  { value: FILTER_CURRENT, text: __(FILTER_CURRENT) },
]);

export const DEFAULT_LABELS = [{ value: 'No label', text: __('No label') }];

export const DEFAULT_MILESTONES = DEFAULT_NONE_ANY.concat([
  { value: 'Upcoming', text: __('Upcoming') },
  { value: 'Started', text: __('Started') },
]);

export const SortDirection = {
  descending: 'descending',
  ascending: 'ascending',
};
/* eslint-enable @gitlab/require-i18n-strings */
