import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';

import IntegrationSectionJiraIssueCreation from '~/integrations/edit/components/sections/jira_issue_creation.vue';
import JiraIssuesFields from '~/integrations/edit/components/jira_issues_fields.vue';
import { useIntegrationForm } from '~/integrations/edit/store';

import { mockIntegrationProps } from '../../mock_data';

Vue.use(PiniaVuePlugin);

describe('IntegrationSectionJiraIssueCreation', () => {
  let wrapper;

  const createComponent = () => {
    const pinia = createTestingPinia({ stubActions: false });
    const store = useIntegrationForm();
    Object.assign(store, {
      customState: { ...mockIntegrationProps },
    });
    wrapper = shallowMount(IntegrationSectionJiraIssueCreation, {
      pinia,
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
