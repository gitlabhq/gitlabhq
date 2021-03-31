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
      error: __("Name can't be blank"),
    },
    enableIntegration: {
      label: s__('AlertSettings|Enable integration'),
      help: s__(
        'AlertSettings|A webhook URL and authorization key will be generated for the integration. Both will be visible after saving the integration in the “View credentials” tab.',
      ),
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
    mapFields: {
      label: s__('AlertSettings|Customize alert payload mapping (optional)'),
      help: s__(
        'AlertSettings|If you intend to create a custom mapping, provide an example payload from your monitoring tool and click the "parse payload fields" button to continue. The sample payload is required for completing the custom mapping;  if you want to skip the mapping step, progress straight to saving your integration.',
      ),
      placeholder: s__('AlertSettings|{ "events": [{ "application": "Name of application" }] }'),
      editPayload: s__('AlertSettings|Edit payload'),
      parsePayload: s__('AlertSettings|Parse payload fields'),
      payloadParsedSucessMsg: s__(
        'AlertSettings|Sample payload has been parsed. You can now map the fields.',
      ),
      resetHeader: s__('AlertSettings|Reset the mapping'),
      resetBody: s__(
        "AlertSettings|If you edit the payload, the stored mapping will be reset, and you'll need to re-map the fields.",
      ),
      resetOk: s__('AlertSettings|Proceed with editing'),
      mapIntro: s__(
        "AlertSettings|The default GitLab alert fields are listed below. If you choose to map your payload keys to GitLab's, please make a selection in the dropdowns below. You may also opt to leave the fields unmapped and move straight to saving your integration.",
      ),
    },
    testPayload: {
      help: s__(
        'AlertSettings|Provide an example payload from the monitoring tool you intend to integrate with. This will allow you to send an alert to an active GitLab alerting point.',
      ),
      placeholder: s__('AlertSettings|{ "events": [{ "application": "Name of application" }] }'),
      modalTitle: s__('AlertSettings|The form has unsaved changes'),
      modalBody: s__('AlertSettings|The form has unsaved changes. How would you like to proceed?'),
      savedAndTest: s__('AlertSettings|Save integration & send'),
      proceedWithoutSave: s__('AlertSettings|Send without saving'),
      cancel: __('Cancel'),
    },
    prometheusFormUrl: {
      label: s__('AlertSettings|Prometheus API base URL'),
      help: s__('AlertSettings|URL cannot be blank and must start with http or https'),
      blankUrlError: __('URL cannot be blank'),
      invalidUrlError: __('URL is invalid'),
    },
    restKeyInfo: {
      label: s__(
        'AlertSettings|Resetting the authorization key for this project will require updating the authorization key in every alert source it is enabled in.',
      ),
    },
  },
  saveIntegration: s__('AlertSettings|Save integration'),
  saveAndTestIntegration: s__('AlertSettings|Save & create test alert'),
  cancelAndClose: __('Cancel and close'),
  send: __('Send'),
  copy: __('Copy'),
  integrationCreated: {
    title: s__('AlertSettings|Integration successfully saved'),
    successMsg: s__(
      'AlertSettings|A URL and authorization key  have been created for your integration. You will need them to setup a webhook and authorize your endpoint to send alerts to GitLab.',
    ),
    btnCaption: s__('AlertSettings|View URL and authorization key'),
  },
  changesSaved: s__('AlertsIntegrations|The integration has been successfully saved.'),
  integrationRemoved: s__('AlertsIntegrations|The integration has been successfully removed.'),
  alertSent: s__(
    'AlertsIntegrations|The test alert has been successfully sent, and should now be visible on your alerts list.',
  ),
  addNewIntegration: s__('AlertSettings|Add new integration'),
};

export const integrationSteps = {
  selectType: 'SELECT_TYPE',
  nameIntegration: 'NAME_INTEGRATION',
  enableHttpIntegration: 'ENABLE_HTTP_INTEGRATION',
  enablePrometheusIntegration: 'ENABLE_PROMETHEUS_INTEGRATION',
  customizeMapping: 'CUSTOMIZE_MAPPING',
};

export const createStepNumbers = {
  [integrationSteps.selectType]: 1,
  [integrationSteps.nameIntegration]: 2,
  [integrationSteps.enableHttpIntegration]: 3,
  [integrationSteps.enablePrometheusIntegration]: 2,
  [integrationSteps.customizeMapping]: 4,
};

export const editStepNumbers = {
  [integrationSteps.nameIntegration]: 1,
  [integrationSteps.enableHttpIntegration]: 2,
  [integrationSteps.enablePrometheusIntegration]: null,
  [integrationSteps.customizeMapping]: 3,
};

export const integrationTypes = {
  none: { value: '', text: s__('AlertSettings|Select integration type') },
  http: { value: 'HTTP', text: s__('AlertSettings|HTTP Endpoint') },
  prometheus: { value: 'PROMETHEUS', text: s__('AlertSettings|Prometheus') },
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

export const tabIndices = {
  configureDetails: 0,
  viewCredentials: 1,
  sendTestAlert: 2,
};

export const testAlertModalId = 'confirmSendTestAlert';
