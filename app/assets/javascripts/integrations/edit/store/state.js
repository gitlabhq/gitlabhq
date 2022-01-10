export default ({ defaultState = null, customState = {} } = {}) => {
  const override = defaultState !== null ? defaultState.id !== customState.inheritFromId : false;

  return {
    override,
    defaultState,
    customState,
    isLoadingJiraIssueTypes: false,
    loadingJiraIssueTypesErrorMessage: '',
    jiraIssueTypes: [],
  };
};
