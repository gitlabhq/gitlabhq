import { s__, __ } from '~/locale';

export const DELETE_INTEGRATION_ERROR = s__(
  'AlertsIntegrations|The integration could not be deleted. Please try again.',
);

export const ADD_INTEGRATION_ERROR = s__(
  'AlertsIntegrations|The integration could not be added. Please try again.',
);

export const UPDATE_INTEGRATION_ERROR = s__(
  'AlertsIntegrations|The current integration could not be updated. Please try again.',
);

export const RESET_INTEGRATION_TOKEN_ERROR = s__(
  'AlertsIntegrations|The integration token could not be reset. Please try again.',
);

export const INTEGRATION_PAYLOAD_TEST_ERROR = s__(
  'AlertsIntegrations|Integration payload is invalid.',
);

export const INTEGRATION_INACTIVE_PAYLOAD_TEST_ERROR = s__(
  'AlertsIntegrations|The integration is currently inactive. Enable the integration to send the test alert.',
);

export const DEFAULT_ERROR = __('Something went wrong on our end.');
