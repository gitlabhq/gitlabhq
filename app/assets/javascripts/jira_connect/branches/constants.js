import { __, s__ } from '~/locale';

export const BRANCHES_PER_PAGE = 20;
export const PROJECTS_PER_PAGE = 20;

export const I18N_NEW_BRANCH_PAGE_TITLE = __('New branch');
export const I18N_NEW_BRANCH_LABEL_DROPDOWN = __('Project');
export const I18N_NEW_BRANCH_LABEL_BRANCH = __('Branch name');
export const I18N_NEW_BRANCH_LABEL_SOURCE = __('Source branch');
export const I18N_NEW_BRANCH_SUBMIT_BUTTON_TEXT = __('Create branch');

export const CREATE_BRANCH_ERROR_GENERIC = s__(
  'JiraConnect|Failed to create branch. Please try again.',
);
export const CREATE_BRANCH_ERROR_WITH_CONTEXT = s__('JiraConnect|Failed to create branch.');

export const CREATE_BRANCH_SUCCESS_ALERT = {
  title: s__('JiraConnect|New branch was successfully created.'),
  message: s__('JiraConnect|You can now close this window and return to Jira.'),
};
