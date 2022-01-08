import { __ } from '~/locale';

export const JIRA_IMPORT_SUCCESS_ALERT_HIDE_MAP_KEY = 'jira-import-success-alert-hide-map';

export const debounceWait = 500;

export const dropdownLabel = __(
  'The GitLab user to which the Jira user %{jiraDisplayName} will be mapped',
);

export const previousImportsMessage = __(`You have imported from this project
  %{numberOfPreviousImports} times before. Each new import will create duplicate issues.`);

export const tableConfig = [
  {
    key: 'jiraDisplayName',
    label: __('Jira display name'),
  },
  {
    key: 'arrow',
    label: '',
  },
  {
    key: 'gitlabUsername',
    label: __('GitLab username'),
  },
];

export const userMappingMessage = __(`Jira users have been imported from the configured Jira
  instance. They can be mapped by selecting a GitLab user from the dropdown in the "GitLab username"
  column. When the form appears, the dropdown defaults to the user conducting the import.`);

// pageSize must match the MAX_USERS value in app/services/jira_import/users_mapper_service.rb
export const userMappingsPageSize = 50;
