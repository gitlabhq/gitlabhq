import { shallowMount } from '@vue/test-utils';

import IntegrationSectionTrigger from '~/integrations/edit/components/sections/trigger.vue';
import TriggerField from '~/integrations/edit/components/trigger_field.vue';
import { createStore } from '~/integrations/edit/store';

import { mockIntegrationProps } from '../../mock_data';

describe('IntegrationSectionTrigger', () => {
  let wrapper;

  const createComponent = () => {
    const store = createStore({
      customState: { ...mockIntegrationProps },
    });
    wrapper = shallowMount(IntegrationSectionTrigger, {
      store,
    });
  };

  const findAllTriggerFields = () => wrapper.findAllComponents(TriggerField);

  describe('template', () => {
    it('renders correct number of TriggerField components', () => {
      createComponent();

      const fields = findAllTriggerFields();
      expect(fields.length).toBe(mockIntegrationProps.triggerEvents.length);
      fields.wrappers.forEach((field, index) => {
        expect(field.props('event')).toBe(mockIntegrationProps.triggerEvents[index]);
      });
    });
  });
});
