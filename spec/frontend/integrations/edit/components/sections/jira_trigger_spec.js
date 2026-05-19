import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';

import IntegrationSectionJiraTrigger from '~/integrations/edit/components/sections/jira_trigger.vue';
import JiraTriggerFields from '~/integrations/edit/components/jira_trigger_fields.vue';
import { useIntegrationForm } from '~/integrations/edit/store';

import { mockIntegrationProps } from '../../mock_data';

Vue.use(PiniaVuePlugin);

describe('IntegrationSectionJiraTrigger', () => {
  let wrapper;

  const createComponent = () => {
    const pinia = createTestingPinia({ stubActions: false });
    const store = useIntegrationForm();
    Object.assign(store, {
      customState: { ...mockIntegrationProps },
    });
    wrapper = shallowMount(IntegrationSectionJiraTrigger, {
      pinia,
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
