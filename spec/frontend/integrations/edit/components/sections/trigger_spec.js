import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';

import IntegrationSectionTrigger from '~/integrations/edit/components/sections/trigger.vue';
import TriggerField from '~/integrations/edit/components/trigger_field.vue';
import { useIntegrationForm } from '~/integrations/edit/store';

import { mockIntegrationProps } from '../../mock_data';

Vue.use(PiniaVuePlugin);

describe('IntegrationSectionTrigger', () => {
  let wrapper;

  const createComponent = () => {
    const pinia = createTestingPinia({ stubActions: false });
    const store = useIntegrationForm();
    Object.assign(store, {
      customState: { ...mockIntegrationProps },
    });
    wrapper = shallowMount(IntegrationSectionTrigger, {
      pinia,
    });
  };

  const findAllTriggerFields = () => wrapper.findAllComponents(TriggerField);

  describe('template', () => {
    it('renders correct number of TriggerField components', () => {
      createComponent();

      const fields = findAllTriggerFields();
      expect(fields).toHaveLength(mockIntegrationProps.triggerEvents.length);
      fields.wrappers.forEach((field, index) => {
        expect(field.props('event')).toBe(mockIntegrationProps.triggerEvents[index]);
      });
    });
  });
});
