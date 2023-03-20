import { shallowMount } from '@vue/test-utils';

import IntegrationSectionConnection from '~/integrations/edit/components/sections/connection.vue';
import ActiveCheckbox from '~/integrations/edit/components/active_checkbox.vue';
import DynamicField from '~/integrations/edit/components/dynamic_field.vue';
import { createStore } from '~/integrations/edit/store';

import { mockIntegrationProps } from '../../mock_data';

describe('IntegrationSectionConnection', () => {
  let wrapper;

  const createComponent = ({ customStateProps = {}, props = {} } = {}) => {
    const store = createStore({
      customState: { ...mockIntegrationProps, ...customStateProps },
    });
    wrapper = shallowMount(IntegrationSectionConnection, {
      propsData: { ...props },
      store,
    });
  };

  const findActiveCheckbox = () => wrapper.findComponent(ActiveCheckbox);
  const findAllDynamicFields = () => wrapper.findAllComponents(DynamicField);

  describe('template', () => {
    describe('ActiveCheckbox', () => {
      describe.each`
        showActive
        ${true}
        ${false}
      `('when `showActive` is $showActive', ({ showActive }) => {
        it(`${showActive ? 'renders' : 'does not render'} ActiveCheckbox`, () => {
          createComponent({
            customStateProps: {
              showActive,
            },
          });

          expect(findActiveCheckbox().exists()).toBe(showActive);
        });
      });
    });

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
