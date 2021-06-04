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
        'AlertSettings|Free versions of GitLab are limited to one integration per type. To add more, %{linkStart}upgrade your subscription%{linkEnd}.',
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
        'AlertSettings|A webhook URL and authorization key is generated for the integration. After you save the integration, both are visible under the “View credentials” tab.',
      ),
    },
    setupCredentials: {
      help: s__(
        'AlertSettings|Use the URL and authorization key below to configure how an external service sends alerts to GitLab. %{linkStart}How do I configure the endpoint?%{linkEnd}',
      ),
      prometheusHelp: s__(
        'AlertSettings|Use the URL and authorization key below to configure how Prometheus sends alerts to GitLab. Review the %{linkStart}GitLab documentation%{linkEnd} to learn how to configure your endpoint.',
      ),
      webhookUrl: s__('AlertSettings|Webhook URL'),
      authorizationKey: s__('AlertSettings|Authorization key'),
      reset: s__('AlertSettings|Reset Key'),
    },
    mapFields: {
      label: s__('AlertSettings|Customize alert payload mapping (optional)'),
      help: s__(
        'AlertSettings|To create a custom mapping, enter an example payload from your monitoring tool, in JSON format. Select the "Parse payload fields" button to continue.',
      ),
      placeholder: s__('AlertSettings|{ "events": [{ "application": "Name of application" }] }'),
      editPayload: s__('AlertSettings|Edit payload'),
      parsePayload: s__('AlertSettings|Parse payload fields'),
      payloadParsedSucessMsg: s__(
        'AlertSettings|Sample payload has been parsed. You can now map the fields.',
      ),
      resetHeader: s__('AlertSettings|Reset the mapping'),
      resetBody: s__('AlertSettings|If you edit the payload, you must re-map the fields again.'),
      resetOk: s__('AlertSettings|Proceed with editing'),
      mapIntro: s__(
        'AlertSettings|You can map default GitLab alert fields to your payload keys in the dropdowns below.',
      ),
    },
    testPayload: {
      help: s__(
        'AlertSettings|Enter an example payload from your selected monitoring tool. This supports sending alerts to a GitLab endpoint.',
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
      help: s__('AlertSettings|URL cannot be blank and must start with http: or https:.'),
      blankUrlError: __('URL cannot be blank'),
      invalidUrlError: __('URL is invalid'),
    },
    restKeyInfo: {
      label: s__(
        'AlertSettings|If you reset the authorization key for this project, you must update the key in every enabled alert source.',
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
      'AlertSettings|GitLab has created a URL and authorization key for your integration. You can use them to set up a webhook and authorize your endpoint to send alerts to GitLab.',
    ),
    btnCaption: s__('AlertSettings|View URL and authorization key'),
  },
  changesSaved: s__('AlertsIntegrations|The integration is saved.'),
  integrationRemoved: s__('AlertsIntegrations|The integration is deleted.'),
  alertSent: s__('AlertsIntegrations|The test alert should now be visible in your alerts list.'),
  addNewIntegration: s__('AlertSettings|Add new integration'),
  settingsTabs: {
    currentIntegrations: s__('AlertSettings|Current integrations'),
    integrationSettings: s__('AlertSettings|Alert settings'),
  },
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

/* Alerts integration settings constants */

export const I18N_ALERT_SETTINGS_FORM = {
  saveBtnLabel: __('Save changes'),
  introText: __('Action to take when receiving an alert. %{docsLink}'),
  introLinkText: __('Learn more.'),
  createIncident: {
    label: __('Create an incident. Incidents are created for each alert triggered.'),
  },
  incidentTemplate: {
    label: __('Incident template (optional).'),
  },
  sendEmail: {
    label: __('Send a single email notification to Owners and Maintainers for new alerts.'),
  },
  autoCloseIncidents: {
    label: __(
      'Automatically close associated incident when a recovery alert notification resolves an alert',
    ),
  },
};

export const NO_ISSUE_TEMPLATE_SELECTED = { key: '', name: __('No template selected') };
export const TAKING_INCIDENT_ACTION_DOCS_LINK =
  '/help/operations/metrics/alerts#trigger-actions-from-alerts';
export const ISSUE_TEMPLATES_DOCS_LINK =
  '/help/user/project/description_templates#create-an-issue-template';
