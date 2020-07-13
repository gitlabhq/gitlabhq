import { __, s__ } from '~/locale';

export const INTEGRATION_TABS_CONFIG = [
  {
    title: s__('IncidentSettings|Alert integration'),
    component: 'AlertsSettingsForm',
    active: true,
  },
  {
    title: s__('IncidentSettings|PagerDuty integration'),
    component: '',
    active: false,
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
  saveBtnLabel: __('Save changes'),
  subHeaderText: s__(
    'IncidentSettings|Set up integrations with external tools to help better manage incidents.',
  ),
};

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
};

export const NO_ISSUE_TEMPLATE_SELECTED = { key: '', name: __('No template selected') };
export const TAKING_INCIDENT_ACTION_DOCS_LINK =
  '/help/user/project/integrations/prometheus#taking-action-on-incidents-ultimate';
export const ISSUE_TEMPLATES_DOCS_LINK =
  '/help/user/project/description_templates#creating-issue-templates';

export const ERROR_MSG = __('There was an error saving your changes.');
