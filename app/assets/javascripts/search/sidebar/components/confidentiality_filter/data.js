import { __ } from '~/locale';

const header = __('Confidentiality');

const filters = {
  ANY: {
    label: __('Any'),
    value: null,
  },
  CONFIDENTIAL: {
    label: __('Confidential'),
    value: 'yes',
  },
  NOT_CONFIDENTIAL: {
    label: __('Not confidential'),
    value: 'no',
  },
};

const scopes = {
  ISSUES: 'issues',
};

const filterByScope = {
  [scopes.ISSUES]: [filters.ANY, filters.CONFIDENTIAL, filters.NOT_CONFIDENTIAL],
};

const filterParam = 'confidential';

export const confidentialFilterData = {
  header,
  filters,
  scopes,
  filterByScope,
  filterParam,
};
