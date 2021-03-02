import { s__, __ } from '~/locale';

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
  integrationTabs: {
    configureDetails: s__('AlertSettings|Configure details'),
    viewCredentials: s__('AlertSettings|View credentials'),
    sendTestAlert: s__('AlertSettings|Send test alert'),
  },
  integrationFormSteps: {
    selectType: {
      label: s__('AlertSettings|Select integration type'),
      enterprise: s__(
        'AlertSettings|In free versions of GitLab, only one integration for each type can be added. %{linkStart}Upgrade your subscription%{linkEnd} to add additional integrations.',
      ),
    },
    nameIntegration: {
      label: s__('AlertSettings|Name integration'),
      placeholder: s__('AlertSettings|Enter integration name'),
      activeToggle: __('Active'),
    },
    setupCredentials: {
      help: s__(
        "AlertSettings|Utilize the URL and authorization key below to authorize an external service to send alerts to GitLab. Review your external service's documentation to learn where to add these details, and the %{linkStart}GitLab documentation%{linkEnd} to learn more about configuring your endpoint.",
      ),
      prometheusHelp: s__(
        'AlertSettings|Utilize the URL and authorization key below to authorize Prometheus to send alerts to GitLab. Review the Prometheus documentation to learn where to add these details, and the %{linkStart}GitLab documentation%{linkEnd} to learn more about configuring your endpoint.',
      ),
      webhookUrl: s__('AlertSettings|Webhook URL'),
      authorizationKey: s__('AlertSettings|Authorization key'),
      reset: s__('AlertSettings|Reset Key'),
    },
    setSamplePayload: {
      label: s__('AlertSettings|Sample alert payload (optional)'),
      testPayloadHelpHttp: s__(
        'AlertSettings|Provide an example payload from the monitoring tool you intend to integrate with. This payload can be used to create a custom mapping (optional).',
      ),
      testPayloadHelp: s__(
        'AlertSettings|Provide an example payload from the monitoring tool you intend to integrate with. This will allow you to send an alert to an active GitLab alerting point.',
      ),
      placeholder: s__('AlertSettings|{ "events": [{ "application": "Name of application" }] }'),
      resetHeader: s__('AlertSettings|Reset the mapping'),
      resetBody: s__(
        "AlertSettings|If you edit the payload, the stored mapping will be reset, and you'll need to re-map the fields.",
      ),
      resetOk: s__('AlertSettings|Proceed with editing'),
      editPayload: s__('AlertSettings|Edit payload'),
      parsePayload: s__('AlertSettings|Parse payload for custom mapping'),
      payloadParsedSucessMsg: s__(
        'AlertSettings|Sample payload has been parsed. You can now map the fields.',
      ),
    },
    mapFields: {
      label: s__('AlertSettings|Map fields (optional)'),
      intro: s__(
        "AlertSettings|If you've provided a sample alert payload, you can create a custom mapping for your endpoint. The default GitLab alert keys are listed below. Please define which payload key should map to the specified GitLab key.",
      ),
    },
    prometheusFormUrl: {
      label: s__('AlertSettings|Prometheus API base URL'),
      help: s__('AlertSettings|URL cannot be blank and must start with http or https'),
    },
    restKeyInfo: {
      label: s__(
        'AlertSettings|Resetting the authorization key for this project will require updating the authorization key in every alert source it is enabled in.',
      ),
    },
  },
  saveIntegration: s__('AlertSettings|Save integration'),
  cancelAndClose: __('Cancel and close'),
  send: s__('AlertSettings|Send'),
  copy: __('Copy'),
};

export const integrationTypes = {
  none: { value: '', text: s__('AlertSettings|Select integration type') },
  http: { value: 'HTTP', text: s__('AlertSettings|HTTP Endpoint') },
  prometheus: { value: 'PROMETHEUS', text: s__('AlertSettings|External Prometheus') },
};

export const typeSet = {
  http: 'HTTP',
  prometheus: 'PROMETHEUS',
};

export const integrationToDeleteDefault = { id: null, name: '' };

export const JSON_VALIDATE_DELAY = 250;

export const targetPrometheusUrlPlaceholder = 'http://prometheus.example.com/';

export const sectionHash = 'js-alert-management-settings';

/* eslint-disable @gitlab/require-i18n-strings */

/**
 * Tracks snowplow event when user views alerts integration list
 */
export const trackAlertIntegrationsViewsOptions = {
  category: 'Alert Integrations',
  action: 'view_alert_integrations_list',
};

export const mappingFields = {
  mapping: 'mapping',
  fallback: 'fallback',
};
