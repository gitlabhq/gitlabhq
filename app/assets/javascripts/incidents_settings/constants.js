import { __, s__ } from '~/locale';

/* Integration tabs constants */
export const INTEGRATION_TABS_CONFIG = [
  {
    title: s__('IncidentSettings|Alert integration'),
    component: 'AlertsSettingsForm',
    active: true,
  },
  {
    title: s__('IncidentSettings|PagerDuty integration'),
    component: 'PagerDutySettingsForm',
    active: true,
  },
  {
    title: s__('IncidentSettings|Grafana integration'),
    component: '',
    active: false,
  },
];

export const I18N_INTEGRATION_TABS = {
  headerText: s__('IncidentSettings|Incidents'),
  expandBtnLabel: __('Expand'),
  subHeaderText: s__(
    'IncidentSettings|Set up integrations with external tools to help better manage incidents.',
  ),
};

/* Alerts integration settings constants */

export const I18N_ALERT_SETTINGS_FORM = {
  saveBtnLabel: __('Save changes'),
  introText: __('Action to take when receiving an alert. %{docsLink}'),
  introLinkText: __('More information.'),
  createIssue: {
    label: __('Create an issue. Issues are created for each alert triggered.'),
  },
  issueTemplate: {
    label: __('Issue template (optional)'),
  },
  sendEmail: {
    label: __('Send a separate email notification to Developers.'),
  },
  autoCloseIncidents: {
    label: __('Automatically close incident issues when the associated Prometheus alert resolves.'),
  },
};

export const NO_ISSUE_TEMPLATE_SELECTED = { key: '', name: __('No template selected') };
export const TAKING_INCIDENT_ACTION_DOCS_LINK =
  '/help/operations/metrics/alerts#trigger-actions-from-alerts';
export const ISSUE_TEMPLATES_DOCS_LINK =
  '/help/user/project/description_templates#creating-issue-templates';

/* PagerDuty integration settings constants */

export const I18N_PAGERDUTY_SETTINGS_FORM = {
  introText: s__(
    'PagerDutySettings|Setting up a webhook with PagerDuty will automatically create a GitLab issue for each PagerDuty incident.',
  ),
  activeToggle: {
    label: s__('PagerDutySettings|Active'),
  },
  webhookUrl: {
    label: s__('PagerDutySettings|Webhook URL'),
    helpText: s__(
      'PagerDutySettings|Create a GitLab issue for each PagerDuty incident by %{docsLink}',
    ),
    helpDocsLink: s__('PagerDutySettings|configuring a webhook in PagerDuty'),
    resetWebhookUrl: s__('PagerDutySettings|Reset webhook URL'),
    copyToClipboard: __('Copy'),
    updateErrMsg: s__('PagerDutySettings|Failed to update Webhook URL'),
    updateSuccessMsg: s__('PagerDutySettings|Webhook URL update was successful'),
    restKeyInfo: s__(
      "PagerDutySettings|Resetting the webhook URL for this project will require updating this integration's settings in PagerDuty.",
    ),
  },
  saveBtnLabel: __('Save changes'),
};

export const CONFIGURE_PAGERDUTY_WEBHOOK_DOCS_LINK = 'https://support.pagerduty.com/docs/webhooks';

/* common constants */
export const ERROR_MSG = __('There was an error saving your changes.');
