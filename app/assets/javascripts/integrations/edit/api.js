import axios from '~/lib/utils/axios_utils';

/**
 *  Test the validity of [integrationFormData].
 * @return Promise<{ issuetypes: []String }> - issuetypes contains valid Jira issue types.
 */
export const testIntegrationSettings = (testPath, integrationFormData) => {
  return axios.put(testPath, integrationFormData);
};
