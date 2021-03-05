import { s__, __ } from '~/locale';

export const i18n = {
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
      label: s__('AlertSettings|Customize alert payload mapping (optional)'),
      intro: s__(
        'AlertSettings|If you intend to create a custom mapping, provide an example payload from your monitoring tool and click "parse payload fields" button to continue. The sample payload is required for completing the custom mapping;  if you want to skip the mapping step, progress straight to saving your integration.',
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
  changesSaved: s__('AlertSettings|Your integration was successfully updated.'),
  cancelAndClose: __('Cancel and close'),
  send: s__('AlertSettings|Send'),
  copy: __('Copy'),
};

export const integrationSteps = {
  selectType: 'SELECT_TYPE',
  nameIntegration: 'NAME_INTEGRATION',
  setPrometheusApiUrl: 'SET_PROMETHEUS_API_URL',
  setSamplePayload: 'SET_SAMPLE_PAYLOAD',
  customizeMapping: 'CUSTOMIZE_MAPPING',
};

export const createStepNumbers = {
  [integrationSteps.selectType]: 1,
  [integrationSteps.nameIntegration]: 2,
  [integrationSteps.setPrometheusApiUrl]: 2,
  [integrationSteps.setSamplePayload]: 3,
  [integrationSteps.customizeMapping]: 4,
};

export const editStepNumbers = {
  [integrationSteps.selectType]: 1,
  [integrationSteps.nameIntegration]: 1,
  [integrationSteps.setPrometheusApiUrl]: null,
  [integrationSteps.setSamplePayload]: 2,
  [integrationSteps.customizeMapping]: 3,
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

/**
 * Tracks snowplow event when user views alerts integration list
 */
export const trackAlertIntegrationsViewsOptions = {
  /* eslint-disable-next-line @gitlab/require-i18n-strings */
  category: 'Alert Integrations',
  action: 'view_alert_integrations_list',
};

export const mappingFields = {
  mapping: 'mapping',
  fallback: 'fallback',
};

export const viewCredentialsTabIndex = 1;
