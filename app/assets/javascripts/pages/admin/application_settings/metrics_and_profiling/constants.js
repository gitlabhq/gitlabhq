import { s__ } from '~/locale';

export const HELPER_TEXT_SERVICE_PING_DISABLED = s__(
  'ApplicationSettings|To enable Registration Features, first enable Service Ping.',
);

export const HELPER_TEXT_SERVICE_PING_ENABLED = s__(
  'ApplicationSettings|You can enable Registration Features because Service Ping is enabled.',
);

export const HELPER_TEXT_OPTIONAL_METRICS_DISABLED = s__(
  'ApplicationSettings|To enable Registration Features, first enable optional data in Service Ping.',
);

export const HELPER_TEXT_OPTIONAL_METRICS_ENABLED = s__(
  'ApplicationSettings|You can enable Registration Features because optional data in Service Ping is enabled.',
);

export const ELEMENT_IDS = Object.freeze({
  HELPER_TEXT: 'service_ping_features_helper_text',
  SERVICE_PING_FEATURES_LABEL: 'service_ping_features_label',
  USAGE_PING_FEATURES_ENABLED: 'application_setting_usage_ping_features_enabled',
  USAGE_PING_ENABLED: 'application_setting_usage_ping_enabled',
  OPTIONAL_METRICS_IN_SERVICE_PING: 'application_setting_include_optional_metrics_in_service_ping',
});
