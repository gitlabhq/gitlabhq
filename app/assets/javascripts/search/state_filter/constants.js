import { __ } from '~/locale';

export const FILTER_HEADER = __('Status');

export const FILTER_TEXT = __('Any Status');

export const FILTER_STATES = {
  ANY: {
    label: __('Any'),
    value: 'all',
  },
  OPEN: {
    label: __('Open'),
    value: 'opened',
  },
  CLOSED: {
    label: __('Closed'),
    value: 'closed',
  },
};
