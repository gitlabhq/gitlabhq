import { __, s__ } from '~/locale';

export const BRANCHES_PER_PAGE = 20;
export const PROJECTS_PER_PAGE = 20;

export const I18N_NEW_BRANCH_LABEL_DROPDOWN = __('Project');
export const I18N_NEW_BRANCH_LABEL_BRANCH = __('Branch name');
export const I18N_NEW_BRANCH_LABEL_SOURCE = __('Source branch');
export const I18N_NEW_BRANCH_SUBMIT_BUTTON_TEXT = __('Create branch');

export const CREATE_BRANCH_ERROR_GENERIC = s__(
  'JiraConnect|Failed to create branch. Please try again.',
);
export const CREATE_BRANCH_ERROR_WITH_CONTEXT = s__('JiraConnect|Failed to create branch.');

export const I18N_PAGE_TITLE_WITH_BRANCH_NAME = s__(
  'JiraConnect|Create branch for Jira issue %{jiraIssue}',
);
export const I18N_PAGE_TITLE_DEFAULT = __('New branch');
export const I18N_NEW_BRANCH_SUCCESS_TITLE = s__(
  'JiraConnect|New branch was successfully created.',
);
export const I18N_NEW_BRANCH_SUCCESS_MESSAGE = s__(
  'JiraConnect|You can now close this window and return to Jira.',
);
export const I18N_NEW_BRANCH_PERMISSION_ALERT = s__(
  "JiraConnect|You don't have permission to create branches for this project. Select a different project or contact the project owner for access. %{linkStart}Learn more.%{linkEnd}",
);
