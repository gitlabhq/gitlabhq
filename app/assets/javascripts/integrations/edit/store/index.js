import { defineStore } from 'pinia';
import {
  I18N_DEFAULT_ERROR_MESSAGE,
  I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE,
  integrationLevels,
} from '~/integrations/constants';
import { testIntegrationSettings } from '../api';

export const useIntegrationForm = defineStore('integrationForm', {
  state: () => ({
    override: false,
    defaultState: null,
    customState: {},
    isLoadingJiraIssueTypes: false,
    loadingJiraIssueTypesErrorMessage: '',
    jiraIssueTypes: [],
  }),
  getters: {
    isInheriting: (state) => (state.defaultState === null ? false : !state.override),
    isProjectLevel: (state) => state.customState.integrationLevel === integrationLevels.PROJECT,
    propsSource() {
      return this.isInheriting ? this.defaultState : this.customState;
    },
    currentKey() {
      return this.isInheriting ? 'admin' : 'custom';
    },
  },
  actions: {
    setOverride(override) {
      this.override = override;
    },
    async requestJiraIssueTypes(formData) {
      this.loadingJiraIssueTypesErrorMessage = '';
      this.isLoadingJiraIssueTypes = true;

      try {
        const { data } = await testIntegrationSettings(this.propsSource.testPath, formData);

        if (data.error || !data.issuetypes?.length) {
          throw new Error(
            data.service_response || data.message || I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE,
          );
        }

        this.jiraIssueTypes = data.issuetypes;
      } catch (error) {
        this.jiraIssueTypes = [];
        this.loadingJiraIssueTypesErrorMessage = error?.message || I18N_DEFAULT_ERROR_MESSAGE;
      } finally {
        this.isLoadingJiraIssueTypes = false;
      }
    },
  },
});
