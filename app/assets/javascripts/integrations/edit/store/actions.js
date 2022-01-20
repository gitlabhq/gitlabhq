import {
  I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE,
  I18N_DEFAULT_ERROR_MESSAGE,
} from '~/integrations/constants';
import { testIntegrationSettings } from '../api';
import * as types from './mutation_types';

export const setOverride = ({ commit }, override) => commit(types.SET_OVERRIDE, override);

export const requestJiraIssueTypes = ({ commit, dispatch, getters }, formData) => {
  commit(types.SET_JIRA_ISSUE_TYPES_ERROR_MESSAGE, '');
  commit(types.SET_IS_LOADING_JIRA_ISSUE_TYPES, true);

  return testIntegrationSettings(getters.propsSource.testPath, formData)
    .then(
      ({
        data: { issuetypes, error, message = I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE },
      }) => {
        if (error || !issuetypes?.length) {
          throw new Error(message);
        }

        dispatch('receiveJiraIssueTypesSuccess', issuetypes);
      },
    )
    .catch(({ message = I18N_DEFAULT_ERROR_MESSAGE }) => {
      dispatch('receiveJiraIssueTypesError', message);
    });
};

export const receiveJiraIssueTypesSuccess = ({ commit }, issueTypes = []) => {
  commit(types.SET_IS_LOADING_JIRA_ISSUE_TYPES, false);
  commit(types.SET_JIRA_ISSUE_TYPES, issueTypes);
};

export const receiveJiraIssueTypesError = ({ commit }, errorMessage) => {
  commit(types.SET_IS_LOADING_JIRA_ISSUE_TYPES, false);
  commit(types.SET_JIRA_ISSUE_TYPES, []);
  commit(types.SET_JIRA_ISSUE_TYPES_ERROR_MESSAGE, errorMessage);
};
