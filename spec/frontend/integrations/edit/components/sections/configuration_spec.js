import { shallowMount } from '@vue/test-utils';

import IntegrationSectionCoonfiguration from '~/integrations/edit/components/sections/configuration.vue';
import DynamicField from '~/integrations/edit/components/dynamic_field.vue';
import { createStore } from '~/integrations/edit/store';

import { mockIntegrationProps } from '../../mock_data';

describe('IntegrationSectionCoonfiguration', () => {
  let wrapper;

  const createComponent = ({ customStateProps = {}, props = {} } = {}) => {
    const store = createStore({
      customState: { ...mockIntegrationProps, ...customStateProps },
    });
    wrapper = shallowMount(IntegrationSectionCoonfiguration, {
      propsData: { ...props },
      store,
    });
  };

  const findAllDynamicFields = () => wrapper.findAllComponents(DynamicField);

  describe('template', () => {
    describe('DynamicField', () => {
      it('renders DynamicField for each field', () => {
        const fields = [
          { name: 'username', type: 'text' },
          { name: 'API token', type: 'password' },
        ];

        createComponent({
          props: {
            fields,
          },
        });

        const dynamicFields = findAllDynamicFields();

        expect(dynamicFields).toHaveLength(2);
        dynamicFields.wrappers.forEach((field, index) => {
          expect(field.props()).toMatchObject(fields[index]);
        });
      });

      it('does not render DynamicField when field is empty', () => {
        createComponent();

        expect(findAllDynamicFields()).toHaveLength(0);
      });
    });
  });
});
