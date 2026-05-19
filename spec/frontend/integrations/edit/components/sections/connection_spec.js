import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { stubComponent } from 'helpers/stub_component';

import IntegrationSectionConnection from '~/integrations/edit/components/sections/connection.vue';
import ActiveCheckbox from '~/integrations/edit/components/active_checkbox.vue';
import DynamicField from '~/integrations/edit/components/dynamic_field.vue';
import JiraAuthFields from '~/integrations/edit/components/jira_auth_fields.vue';
import { jiraAuthTypes } from '~/integrations/constants';
import { useIntegrationForm } from '~/integrations/edit/store';

import { mockIntegrationProps, mockJiraAuthFields, mockField } from '../../mock_data';

Vue.use(PiniaVuePlugin);

describe('IntegrationSectionConnection', () => {
  let wrapper;

  const JiraAuthFieldsStub = stubComponent(JiraAuthFields, {
    template: `<div />`,
  });

  const createComponent = ({ customStateProps = {}, props = {} } = {}) => {
    const pinia = createTestingPinia({ stubActions: false });
    const store = useIntegrationForm();
    Object.assign(store, {
      customState: { ...mockIntegrationProps, ...customStateProps },
    });
    wrapper = shallowMount(IntegrationSectionConnection, {
      propsData: { ...props },
      pinia,
      stubs: {
        JiraAuthFields: JiraAuthFieldsStub,
      },
    });
  };

  const findActiveCheckbox = () => wrapper.findComponent(ActiveCheckbox);
  const findAllDynamicFields = () => wrapper.findAllComponents(DynamicField);
  const findJiraAuthFields = () => wrapper.findComponent(JiraAuthFields);

  describe('template', () => {
    describe('ActiveCheckbox', () => {
      describe.each`
        manualActivation
        ${true}
        ${false}
      `('when `manualActivation` is $manualActivation', ({ manualActivation }) => {
        it(`${manualActivation ? 'renders' : 'does not render'} ActiveCheckbox`, () => {
          createComponent({
            customStateProps: {
              manualActivation,
            },
          });

          expect(findActiveCheckbox().exists()).toBe(manualActivation);
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

      it('does not render DynamicField when fields is empty', () => {
        createComponent();

        expect(findAllDynamicFields()).toHaveLength(0);
      });
    });

    describe('when integration is not Jira', () => {
      it('does not render JiraAuthFields', () => {
        createComponent();

        expect(findJiraAuthFields().exists()).toBe(false);
      });
    });

    describe('when integration is Jira', () => {
      beforeEach(() => {
        createComponent({
          customStateProps: {
            type: 'jira',
          },
          props: {
            fields: [mockField, ...mockJiraAuthFields],
          },
        });
      });

      it('renders JiraAuthFields', () => {
        expect(findJiraAuthFields().exists()).toBe(true);
        expect(findJiraAuthFields().props('fields')).toEqual(mockJiraAuthFields);
      });

      it('filters out Jira auth fields for DynamicField', () => {
        expect(findAllDynamicFields()).toHaveLength(1);
        expect(findAllDynamicFields().at(0).props('name')).toBe(mockField.name);
      });

      it('updates auth type when JiraAuthFields emits change-auth-type', async () => {
        const serviceAccountAuthType = jiraAuthTypes.SERVICE_ACCOUNT;

        findJiraAuthFields().vm.$emit('change-auth-type', serviceAccountAuthType);

        await nextTick();

        expect(findJiraAuthFields().props('currentAuthType')).toBe(serviceAccountAuthType);
      });
    });
  });
});
