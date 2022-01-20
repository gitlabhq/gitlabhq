import * as types from '~/integrations/edit/store/mutation_types';
import mutations from '~/integrations/edit/store/mutations';
import createState from '~/integrations/edit/store/state';

describe('Integration form store mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe(`${types.SET_OVERRIDE}`, () => {
    it('sets override', () => {
      mutations[types.SET_OVERRIDE](state, true);

      expect(state.override).toBe(true);
    });
  });

  describe(`${types.SET_JIRA_ISSUE_TYPES}`, () => {
    it('sets jiraIssueTypes', () => {
      const jiraIssueTypes = ['issue', 'epic'];
      mutations[types.SET_JIRA_ISSUE_TYPES](state, jiraIssueTypes);

      expect(state.jiraIssueTypes).toBe(jiraIssueTypes);
    });
  });

  describe(`${types.SET_IS_LOADING_JIRA_ISSUE_TYPES}`, () => {
    it.each([true, false])('sets isLoadingJiraIssueTypes to "%s"', (isLoading) => {
      mutations[types.SET_IS_LOADING_JIRA_ISSUE_TYPES](state, isLoading);

      expect(state.isLoadingJiraIssueTypes).toBe(isLoading);
    });
  });

  describe(`${types.SET_JIRA_ISSUE_TYPES_ERROR_MESSAGE}`, () => {
    it('sets loadingJiraIssueTypesErrorMessage', () => {
      const errorMessage = 'something went wrong';
      mutations[types.SET_JIRA_ISSUE_TYPES_ERROR_MESSAGE](state, errorMessage);

      expect(state.loadingJiraIssueTypesErrorMessage).toBe(errorMessage);
    });
  });
});
