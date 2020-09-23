import { __ } from '~/locale';

export const FILTER_HEADER = __('Status');

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
  MERGED: {
    label: __('Merged'),
    value: 'merged',
  },
};

export const SCOPES = {
  ISSUES: 'issues',
  MERGE_REQUESTS: 'merge_requests',
};

export const FILTER_STATES_BY_SCOPE = {
  [SCOPES.ISSUES]: [FILTER_STATES.ANY, FILTER_STATES.OPEN, FILTER_STATES.CLOSED],
  [SCOPES.MERGE_REQUESTS]: [
    FILTER_STATES.ANY,
    FILTER_STATES.OPEN,
    FILTER_STATES.MERGED,
    FILTER_STATES.CLOSED,
  ],
};

export const FILTER_PARAM = 'state';
