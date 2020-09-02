/* eslint-disable @gitlab/require-i18n-strings */
import { __ } from '~/locale';

const DEFAULT_LABEL_NO_LABEL = { value: 'No label', text: __('No label') };
export const DEFAULT_LABEL_NONE = { value: 'None', text: __('None') };
export const DEFAULT_LABEL_ANY = { value: 'Any', text: __('Any') };

export const DEFAULT_LABELS = [DEFAULT_LABEL_NO_LABEL];

export const DEBOUNCE_DELAY = 200;

export const SortDirection = {
  descending: 'descending',
  ascending: 'ascending',
};

export const DEFAULT_MILESTONES = [
  DEFAULT_LABEL_NONE,
  DEFAULT_LABEL_ANY,
  { value: 'Upcoming', text: __('Upcoming') },
  { value: 'Started', text: __('Started') },
];

/* eslint-enable @gitlab/require-i18n-strings */
