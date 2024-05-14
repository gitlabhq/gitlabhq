import { __ } from '~/locale';

export const ENVIRONMENT_QUERY_LIMIT = 30;

export const ALL_ENVIRONMENTS_OPTION = {
  type: '*',
  text: __('All (default)'),
};

export const NO_ENVIRONMENT_OPTION = {
  // TODO: This is a placeholder value. It will be replaced with the actual value used once it's implemented on the backend
  type: 'Not applicable',
  text: __('Not applicable'),
};

export const ENVIRONMENT_FETCH_ERROR = __(
  'There was an error fetching the environments information.',
);
