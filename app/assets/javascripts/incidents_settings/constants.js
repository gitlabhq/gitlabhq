import { __, s__ } from '~/locale';

/* Integration tabs constants */
export const INTEGRATION_TABS_CONFIG = [
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
    'IncidentSettings|Fine-tune incident settings and set up integrations with external tools to help better manage incidents.',
  ),
};

/* PagerDuty integration settings constants */

export const I18N_PAGERDUTY_SETTINGS_FORM = {
  introText: s__(
    'PagerDutySettings|Create a GitLab incident for each PagerDuty incident by %{linkStart}configuring a webhook in PagerDuty%{linkEnd}',
  ),
  activeToggle: {
    label: s__('PagerDutySettings|Active'),
  },
  webhookUrl: {
    label: s__('PagerDutySettings|Webhook URL'),
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
