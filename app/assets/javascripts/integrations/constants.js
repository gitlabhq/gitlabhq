import { s__, __ } from '~/locale';

export const TEST_INTEGRATION_EVENT = 'testIntegration';
export const SAVE_INTEGRATION_EVENT = 'saveIntegration';
export const GET_JIRA_ISSUE_TYPES_EVENT = 'getJiraIssueTypes';
export const TOGGLE_INTEGRATION_EVENT = 'toggleIntegration';
export const VALIDATE_INTEGRATION_FORM_EVENT = 'validateIntegrationForm';

export const integrationLevels = {
  GROUP: 'group',
  INSTANCE: 'instance',
};

export const defaultIntegrationLevel = integrationLevels.INSTANCE;

export const overrideDropdownDescriptions = {
  [integrationLevels.GROUP]: s__(
    'Integrations|Default settings are inherited from the group level.',
  ),
  [integrationLevels.INSTANCE]: s__(
    'Integrations|Default settings are inherited from the instance level.',
  ),
};

export const I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE = s__(
  'Integrations|Connection failed. Please check your settings.',
);
export const I18N_DEFAULT_ERROR_MESSAGE = __('Something went wrong on our end.');
export const I18N_SUCCESSFUL_CONNECTION_MESSAGE = s__('Integrations|Connection successful.');
