import { __ } from '~/locale';

const header = __('Status');

const filters = {
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

const scopes = {
  ISSUES: 'issues',
  MERGE_REQUESTS: 'merge_requests',
};

const filterByScope = {
  [scopes.ISSUES]: [filters.ANY, filters.OPEN, filters.CLOSED],
  [scopes.MERGE_REQUESTS]: [filters.ANY, filters.OPEN, filters.MERGED, filters.CLOSED],
};

const filterParam = 'state';

export const stateFilterData = {
  header,
  filters,
  scopes,
  filterByScope,
  filterParam,
};
