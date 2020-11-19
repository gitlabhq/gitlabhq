import { s__ } from '~/locale';

// TODO: Remove this as part of the form old removal
export const i18n = {
  usageSection: s__(
    'AlertSettings|You must provide this URL and authorization key to authorize an external service to send alerts to GitLab. You can provide this URL and key to multiple services. After configuring an external service, alerts from your service will display on the GitLab %{linkStart}Alerts%{linkEnd} page.',
  ),
  setupSection: s__(
    "AlertSettings|Review your external service's documentation to learn where to provide this information to your external service, and the %{linkStart}GitLab documentation%{linkEnd} to learn more about configuring your endpoint.",
  ),
  errorMsg: s__('AlertSettings|There was an error updating the alert settings.'),
  errorKeyMsg: s__(
    'AlertSettings|There was an error while trying to reset the key. Please refresh the page to try again.',
  ),
  restKeyInfo: s__(
    'AlertSettings|Resetting the authorization key for this project will require updating the authorization key in every alert source it is enabled in.',
  ),
  changesSaved: s__('AlertSettings|Your integration was successfully updated.'),
  prometheusInfo: s__('AlertSettings|Add URL and auth key to your Prometheus config file'),
  integrationsInfo: s__(
    'AlertSettings|Learn more about our our upcoming %{linkStart}integrations%{linkEnd}',
  ),
  resetKey: s__('AlertSettings|Reset key'),
  copyToClipboard: s__('AlertSettings|Copy'),
  apiBaseUrlLabel: s__('AlertSettings|API URL'),
  authKeyLabel: s__('AlertSettings|Authorization key'),
  urlLabel: s__('AlertSettings|Webhook URL'),
  activeLabel: s__('AlertSettings|Active'),
  apiBaseUrlHelpText: s__('AlertSettings|URL cannot be blank and must start with http or https'),
  testAlertInfo: s__('AlertSettings|Test alert payload'),
  alertJson: s__('AlertSettings|Alert test payload'),
  alertJsonPlaceholder: s__('AlertSettings|Enter test alert JSON....'),
  testAlertFailed: s__('AlertSettings|Test failed. Do you still want to save your changes anyway?'),
  testAlertSuccess: s__(
    'AlertSettings|Test alert sent successfully. If you have made other changes, please save them now.',
  ),
  authKeyRest: s__(
    'AlertSettings|Authorization key has been successfully reset. Please save your changes now.',
  ),
  integration: s__('AlertSettings|Integration'),
};

// TODO: Delete as part of old form removal in 13.6
export const integrationTypes = [
  { value: 'HTTP', text: s__('AlertSettings|HTTP Endpoint') },
  { value: 'PROMETHEUS', text: s__('AlertSettings|External Prometheus') },
  { value: 'OPSGENIE', text: s__('AlertSettings|Opsgenie') },
];

export const integrationTypesNew = [
  { value: '', text: s__('AlertSettings|Select integration type') },
  ...integrationTypes,
];

export const typeSet = {
  http: 'HTTP',
  prometheus: 'PROMETHEUS',
  opsgenie: 'OPSGENIE',
};

export const integrationToDeleteDefault = { id: null, name: '' };

export const JSON_VALIDATE_DELAY = 250;

export const targetPrometheusUrlPlaceholder = 'http://prometheus.example.com/';
export const targetOpsgenieUrlPlaceholder = 'https://app.opsgenie.com/alert/list/';

export const sectionHash = 'js-alert-management-settings';

/* eslint-disable @gitlab/require-i18n-strings */

/**
 * Tracks snowplow event when user views alerts integration list
 */
export const trackAlertIntegrationsViewsOptions = {
  category: 'Alert Integrations',
  action: 'view_alert_integrations_list',
};
