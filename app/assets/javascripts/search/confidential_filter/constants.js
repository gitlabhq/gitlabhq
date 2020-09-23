import { __ } from '~/locale';

export const FILTER_HEADER = __('Confidentiality');

export const FILTER_STATES = {
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

export const SCOPES = {
  ISSUES: 'issues',
};

export const FILTER_STATES_BY_SCOPE = {
  [SCOPES.ISSUES]: [FILTER_STATES.ANY, FILTER_STATES.CONFIDENTIAL, FILTER_STATES.NOT_CONFIDENTIAL],
};

export const FILTER_PARAM = 'confidential';
