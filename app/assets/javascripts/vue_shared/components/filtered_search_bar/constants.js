import { __ } from '~/locale';

export const ANY_AUTHOR = 'Any';

export const NO_LABEL = 'No label';

export const DEBOUNCE_DELAY = 200;

export const SortDirection = {
  descending: 'descending',
  ascending: 'ascending',
};

export const defaultMilestones = [
  // eslint-disable-next-line @gitlab/require-i18n-strings
  { value: 'None', text: __('None') },
  // eslint-disable-next-line @gitlab/require-i18n-strings
  { value: 'Any', text: __('Any') },
  // eslint-disable-next-line @gitlab/require-i18n-strings
  { value: 'Upcoming', text: __('Upcoming') },
  // eslint-disable-next-line @gitlab/require-i18n-strings
  { value: 'Started', text: __('Started') },
];
