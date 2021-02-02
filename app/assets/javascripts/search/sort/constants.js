import { __ } from '~/locale';

export const SORT_DIRECTION_UI = {
  disabled: {
    direction: null,
    tooltip: '',
    icon: 'sort-highest',
  },
  desc: {
    direction: 'desc',
    tooltip: __('Sort direction: Descending'),
    icon: 'sort-highest',
  },
  asc: {
    direction: 'asc',
    tooltip: __('Sort direction: Ascending'),
    icon: 'sort-lowest',
  },
};
