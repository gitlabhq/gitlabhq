import * as types from './mutation_types';

export default {
  [types.SET_OVERRIDE](state, override) {
    state.override = override;
  },
  [types.SET_JIRA_ISSUE_TYPES](state, jiraIssueTypes) {
    state.jiraIssueTypes = jiraIssueTypes;
  },
  [types.SET_IS_LOADING_JIRA_ISSUE_TYPES](state, isLoadingJiraIssueTypes) {
    state.isLoadingJiraIssueTypes = isLoadingJiraIssueTypes;
  },
  [types.SET_JIRA_ISSUE_TYPES_ERROR_MESSAGE](state, errorMessage) {
    state.loadingJiraIssueTypesErrorMessage = errorMessage;
  },
};
