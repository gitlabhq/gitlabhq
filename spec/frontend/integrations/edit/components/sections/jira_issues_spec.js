import { shallowMount } from '@vue/test-utils';

import IntegrationSectionJiraIssue from '~/integrations/edit/components/sections/jira_issues.vue';
import JiraIssuesFields from '~/integrations/edit/components/jira_issues_fields.vue';
import { createStore } from '~/integrations/edit/store';

import { mockIntegrationProps } from '../../mock_data';

describe('IntegrationSectionJiraIssue', () => {
  let wrapper;

  const createComponent = () => {
    const store = createStore({
      customState: { ...mockIntegrationProps },
    });
    wrapper = shallowMount(IntegrationSectionJiraIssue, {
      store,
    });
  };

  const findJiraIssuesFields = () => wrapper.findComponent(JiraIssuesFields);

  describe('template', () => {
    it('renders JiraIssuesFields', () => {
      createComponent();

      expect(findJiraIssuesFields().exists()).toBe(true);
    });
  });
});
