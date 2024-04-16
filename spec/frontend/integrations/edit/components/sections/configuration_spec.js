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

      it('applies classes to the fields', () => {
        const fieldClass = 'dummy';
        const fields = [
          { name: 'username', type: 'text' },
          { name: 'API token', type: 'password' },
        ];
        createComponent({
          props: { fieldClass, fields },
        });

        const dynamicFields = findAllDynamicFields();

        expect(dynamicFields).toHaveLength(2);
        dynamicFields.wrappers.forEach((field) => {
          expect(field.props()).toMatchObject({ fieldClass });
        });
      });

      it('emits update event with field when Dynamic text field emits event', () => {
        const fields = [{ name: 'username', type: 'text' }];

        createComponent({
          props: {
            fields,
          },
        });

        const dynamicFields = findAllDynamicFields();

        const [dynamicField] = dynamicFields.wrappers;

        dynamicField.vm.$emit('update', 'example');

        expect(wrapper.emitted('update')).toEqual([[{ value: 'example', field: fields[0] }]]);
      });

      it('does not render DynamicField when field is empty', () => {
        createComponent();

        expect(findAllDynamicFields()).toHaveLength(0);
      });
    });
  });
});
