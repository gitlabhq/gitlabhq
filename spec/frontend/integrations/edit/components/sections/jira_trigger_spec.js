import { shallowMount } from '@vue/test-utils';

import IntegrationSectionJiraTrigger from '~/integrations/edit/components/sections/jira_trigger.vue';
import JiraTriggerFields from '~/integrations/edit/components/jira_trigger_fields.vue';
import { createStore } from '~/integrations/edit/store';

import { mockIntegrationProps } from '../../mock_data';

describe('IntegrationSectionJiraTrigger', () => {
  let wrapper;

  const createComponent = () => {
    const store = createStore({
      customState: { ...mockIntegrationProps },
    });
    wrapper = shallowMount(IntegrationSectionJiraTrigger, {
      store,
    });
  };

  const findJiraTriggerFields = () => wrapper.findComponent(JiraTriggerFields);

  describe('template', () => {
    it('renders JiraTriggerFields', () => {
      createComponent();

      expect(findJiraTriggerFields().exists()).toBe(true);
    });
  });
});
