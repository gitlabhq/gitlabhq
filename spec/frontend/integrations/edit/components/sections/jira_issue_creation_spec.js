import { shallowMount } from '@vue/test-utils';

import IntegrationSectionJiraIssueCreation from '~/integrations/edit/components/sections/jira_issue_creation.vue';
import JiraIssuesFields from '~/integrations/edit/components/jira_issues_fields.vue';
import { createStore } from '~/integrations/edit/store';

import { mockIntegrationProps } from '../../mock_data';

describe('IntegrationSectionJiraIssueCreation', () => {
  let wrapper;

  const createComponent = () => {
    const store = createStore({
      customState: { ...mockIntegrationProps },
    });
    wrapper = shallowMount(IntegrationSectionJiraIssueCreation, {
      store,
    });
  };

  const findJiraIssuesFields = () => wrapper.findComponent(JiraIssuesFields);

  describe('template', () => {
    it('renders JiraIssuesFields', () => {
      createComponent();

      expect(findJiraIssuesFields().exists()).toBe(true);
      expect(findJiraIssuesFields().props()).toMatchObject({
        isIssueCreation: true,
      });
    });
  });
});
