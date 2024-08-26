import {
  GlForm,
  GlFormSelect,
  GlFormInput,
  GlToggle,
  GlFormTextarea,
  GlTab,
  GlLink,
  GlModal,
} from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import MappingBuilder from '~/alerts_settings/components/alert_mapping_builder.vue';
import AlertsSettingsForm from '~/alerts_settings/components/alerts_settings_form.vue';
import { typeSet } from '~/alerts_settings/constants';
import parseSamplePayloadQuery from '~/alerts_settings/graphql/queries/parse_sample_payload.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import parsedMapping from '../mocks/parsed_mapping.json';
import alertFields from '../mocks/alert_fields.json';

const scrollIntoViewMock = jest.fn();
HTMLElement.prototype.scrollIntoView = scrollIntoViewMock;

Vue.use(VueApollo);

describe('AlertsSettingsForm', () => {
  let wrapper;
  const mockToastShow = jest.fn();
  let apolloProvider;
  const parseSamplePayloadSpy = jest.fn().mockResolvedValue({
    data: {
      project: {
        id: '1',
        alertManagementPayloadFields: [{ path: 'Foo', label: 'title', type: 'STRING' }],
      },
    },
  });

  const createComponent = async ({
    mountFn = mount,
    props = {},
    multiIntegrations = true,
    currentIntegration = null,
    mockParseSamplePayloadQuery = parseSamplePayloadSpy,
  } = {}) => {
    const mockResolvers = {
      Query: {
        currentIntegration() {
          return currentIntegration;
        },
      },
    };

    apolloProvider = createMockApollo(
      [[parseSamplePayloadQuery, mockParseSamplePayloadQuery]],
      mockResolvers,
    );

    wrapper = extendedWrapper(
      mountFn(AlertsSettingsForm, {
        apolloProvider,
        propsData: {
          loading: false,
          canAddIntegration: true,
          ...props,
        },
        provide: {
          multiIntegrations,
        },
        mocks: {
          $toast: {
            show: mockToastShow,
          },
        },
      }),
    );

    await waitForPromises();
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findSelect = () => wrapper.findComponent(GlFormSelect);
  const findFormFields = () => wrapper.findAllComponents(GlFormInput);
  const findFormToggle = () => wrapper.findComponent(GlToggle);
  const findSamplePayloadSection = () => wrapper.findByTestId('sample-payload-section');
  const findResetPayloadModal = () => wrapper.findComponent(GlModal);
  const findMappingBuilder = () => wrapper.findComponent(MappingBuilder);
  const findSubmitButton = () => wrapper.findByTestId('integration-form-submit');
  const findMultiSupportText = () => wrapper.findByTestId('multi-integrations-not-supported');
  const findJsonTestSubmit = () => wrapper.findByTestId('send-test-alert');
  const findJsonTextArea = () => wrapper.findByTestId('test-payload-field');
  const findActionBtn = () => wrapper.findByTestId('payload-action-btn');
  const findTabs = () => wrapper.findAllComponents(GlTab);

  const selectOptionAtIndex = async (index) => {
    const options = findSelect().findAll('option');
    await options.at(index).setSelected();
  };

  const enableIntegration = (index, value = '') => {
    if (value !== '') {
      findFormFields().at(index).setValue(value);
    }

    findFormToggle().vm.$emit('change', true);
  };

  afterEach(() => {
    apolloProvider = null;
  });

  describe('with default values', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('render the initial form with only an integration type dropdown', () => {
      expect(findForm().exists()).toBe(true);
      expect(findSelect().exists()).toBe(true);
      expect(findMultiSupportText().exists()).toBe(false);
      expect(findFormFields()).toHaveLength(0);
    });

    it('shows the rest of the form when the dropdown is used', async () => {
      await selectOptionAtIndex(1);

      expect(findFormFields().at(0).isVisible()).toBe(true);
    });

    it('disables the dropdown and shows help text when multi integrations are not supported', async () => {
      await createComponent({ mountFn: shallowMount, props: { canAddIntegration: false } });

      expect(findSelect().attributes('disabled')).toBeDefined();
      expect(findMultiSupportText().exists()).toBe(true);
    });

    it('hides the name input when the selected value is prometheus', async () => {
      await createComponent();
      await selectOptionAtIndex(2);

      expect(findFormFields()).toHaveLength(0);
    });

    it('verify pricing link url', async () => {
      await createComponent({ props: { canAddIntegration: false } });

      const link = findMultiSupportText().findComponent(GlLink);
      expect(link.attributes('href')).toMatch(/https:\/\/about.gitlab.(com|cn)\/pricing/);
    });

    describe('form tabs', () => {
      it('renders 3 tabs', () => {
        expect(findTabs()).toHaveLength(3);
      });

      it('only first tab is enabled on integration create', async () => {
        await createComponent();

        const tabs = findTabs();
        expect(tabs.at(0).find('[role="tabpanel"]').classes('disabled')).toBe(false);
        expect(tabs.at(1).find('[role="tabpanel"]').classes('disabled')).toBe(true);
        expect(tabs.at(2).find('[role="tabpanel"]').classes('disabled')).toBe(true);
      });

      it('all tabs are enabled on integration edit', async () => {
        const currentIntegration = { id: 1 };
        await createComponent({ currentIntegration });

        const tabs = findTabs();
        expect(tabs.at(0).find('[role="tabpanel"]').classes('disabled')).toBe(false);
        expect(tabs.at(1).find('[role="tabpanel"]').classes('disabled')).toBe(false);
        expect(tabs.at(2).find('[role="tabpanel"]').classes('disabled')).toBe(false);
      });
    });
  });

  describe('submitting integration form', () => {
    describe('HTTP', () => {
      it('create with custom mapping', async () => {
        await createComponent({ props: { alertFields } });

        const integrationName = 'Test integration';
        await selectOptionAtIndex(1);

        enableIntegration(0, integrationName);

        const sampleMapping = parsedMapping.payloadAttributeMappings;
        findMappingBuilder().vm.$emit('onMappingUpdate', sampleMapping);
        findForm().trigger('submit');

        expect(wrapper.emitted('create-new-integration')[0][0]).toMatchObject({
          type: typeSet.http,
          variables: {
            name: integrationName,
            active: true,
            payloadAttributeMappings: sampleMapping,
            payloadExample: '{}',
          },
        });
      });

      it('update', async () => {
        const currentIntegration = {
          id: '1',
          name: 'Test integration pre',
          type: typeSet.http,
        };
        await createComponent({ currentIntegration });

        const updatedIntegrationName = 'Test integration post';
        enableIntegration(0, updatedIntegrationName);

        expect(findSubmitButton().exists()).toBe(true);
        expect(findSubmitButton().text()).toBe('Save integration');

        await nextTick();
        await findSubmitButton().trigger('click');

        expect(wrapper.emitted('update-integration')[0][0]).toMatchObject({
          type: typeSet.http,
          variables: {
            name: updatedIntegrationName,
            active: true,
            payloadAttributeMappings: [],
            payloadExample: '{}',
          },
        });
      });
    });

    describe('PROMETHEUS', () => {
      it('create', async () => {
        await createComponent();
        await selectOptionAtIndex(2);
        enableIntegration(0);

        expect(findSubmitButton().exists()).toBe(true);
        expect(findSubmitButton().text()).toBe('Save integration');

        findForm().trigger('submit');

        expect(wrapper.emitted('create-new-integration')[0][0]).toMatchObject({
          type: typeSet.prometheus,
          variables: { active: true },
        });
      });

      it('update', async () => {
        const currentIntegration = {
          id: '1',
          type: typeSet.prometheus,
        };
        await createComponent({ currentIntegration });

        enableIntegration(0);

        expect(findSubmitButton().exists()).toBe(true);
        expect(findSubmitButton().text()).toBe('Save integration');

        findForm().trigger('submit');

        expect(wrapper.emitted('update-integration')[0][0]).toMatchObject({
          type: typeSet.prometheus,
          variables: { active: true },
        });
      });
    });
  });

  describe('submitting the integration with a JSON test payload', () => {
    beforeEach(async () => {
      const currentIntegration = { id: '1', name: 'Test' };
      await createComponent({ currentIntegration });
    });

    it('should not allow a user to test invalid JSON', async () => {
      await findJsonTextArea().setValue('Invalid JSON');

      jest.runAllTimers();
      await nextTick();

      const jsonTestSubmit = findJsonTestSubmit();
      expect(jsonTestSubmit.exists()).toBe(true);
      expect(jsonTestSubmit.text()).toBe('Send');
      expect(jsonTestSubmit.props('disabled')).toBe(true);
    });

    it('should allow for the form to be automatically saved if the test payload is successfully submitted', async () => {
      await findJsonTextArea().setValue('{ "value": "value" }');

      jest.runAllTimers();
      await nextTick();
      expect(findJsonTestSubmit().props('disabled')).toBe(false);
    });
  });

  describe('Test payload section for HTTP integration', () => {
    const validSamplePayload = JSON.stringify(alertFields);
    const emptySamplePayload = '{}';
    const currentIntegration = {
      id: '1',
      name: 'Test',
      type: typeSet.http,
      payloadExample: emptySamplePayload,
      payloadAttributeMappings: [],
    };

    beforeEach(async () => {
      await createComponent({
        currentIntegration,
        props: { alertFields },
      });
    });

    describe.each`
      context                                      | payload               | resetPayloadAndMappingConfirmed | disabled
      ${'valid payload, confirmed and enabled'}    | ${validSamplePayload} | ${true}                         | ${undefined}
      ${'empty payload, confirmed and enabled'}    | ${emptySamplePayload} | ${true}                         | ${undefined}
      ${'valid payload, unconfirmed and disabled'} | ${validSamplePayload} | ${false}                        | ${'disabled'}
      ${'empty payload, unconfirmed and enabled'}  | ${emptySamplePayload} | ${false}                        | ${undefined}
    `('given $context', ({ payload, resetPayloadAndMappingConfirmed, disabled }) => {
      const payloadResetMsg = resetPayloadAndMappingConfirmed
        ? 'was confirmed'
        : 'was not confirmed';
      const enabledState = disabled === 'disabled' ? 'disabled' : 'enabled';
      const validPayloadMsg = payload === emptySamplePayload ? 'not valid' : 'valid';

      it(`textarea should be ${enabledState} when payload reset ${payloadResetMsg} and payload is ${validPayloadMsg}`, async () => {
        const updatedCurrentIntegration = {
          id: '1',
          name: 'Test',
          type: typeSet.http,
          payloadExample: payload,
          payloadAttributeMappings: [],
        };

        await createComponent({
          currentIntegration: updatedCurrentIntegration,
          props: { alertFields },
        });

        if (resetPayloadAndMappingConfirmed) {
          findResetPayloadModal().vm.$emit('ok');
        }

        await nextTick();

        expect(
          findSamplePayloadSection().findComponent(GlFormTextarea).attributes('disabled'),
        ).toBe(disabled);
      });
    });

    describe('action buttons for sample payload', () => {
      describe.each`
        context                         | resetPayloadAndMappingConfirmed | payloadExample        | caption
        ${'valid payload, unconfirmed'} | ${false}                        | ${validSamplePayload} | ${'Edit payload'}
        ${'empty payload, confirmed'}   | ${true}                         | ${emptySamplePayload} | ${'Parse payload fields'}
        ${'valid payload, confirmed'}   | ${true}                         | ${validSamplePayload} | ${'Parse payload fields'}
        ${'empty payload, unconfirmed'} | ${false}                        | ${emptySamplePayload} | ${'Parse payload fields'}
      `('given $context', ({ resetPayloadAndMappingConfirmed, payloadExample, caption }) => {
        const samplePayloadMsg = payloadExample ? 'was provided' : 'was not provided';
        const payloadResetMsg = resetPayloadAndMappingConfirmed
          ? 'was confirmed'
          : 'was not confirmed';

        it(`shows ${caption} button when sample payload ${samplePayloadMsg} and payload reset ${payloadResetMsg}`, async () => {
          const updatedCurrentIntegration = {
            type: typeSet.http,
            payloadExample,
            payloadAttributeMappings: [],
          };

          await createComponent({
            currentIntegration: updatedCurrentIntegration,
            props: { alertFields },
          });

          if (resetPayloadAndMappingConfirmed) {
            findResetPayloadModal().vm.$emit('ok');
          }

          await nextTick();
          expect(findActionBtn().text()).toBe(caption);
        });
      });
    });

    describe('Parsing payload', () => {
      it('displays a toast message on successful parse', async () => {
        findActionBtn().vm.$emit('click');
        await waitForPromises();

        expect(mockToastShow).toHaveBeenCalledWith(
          'Sample payload has been parsed. You can now map the fields.',
        );
      });

      it('displays an error message under payload field on unsuccessful parse', async () => {
        const errorMessage = 'Error parsing paylod';
        const mockParseSamplePayloadQuery = jest.fn().mockRejectedValue({ message: errorMessage });
        await createComponent({
          currentIntegration,
          props: { alertFields },
          mockParseSamplePayloadQuery,
        });
        findActionBtn().vm.$emit('click');

        await waitForPromises();

        expect(findSamplePayloadSection().find('.invalid-feedback').text()).toBe(errorMessage);
      });
    });
  });

  describe('Mapping builder section', () => {
    describe.each`
      alertFieldsProvided | multiIntegrations | integrationOption | visible
      ${true}             | ${true}           | ${1}              | ${true}
      ${true}             | ${true}           | ${2}              | ${false}
      ${true}             | ${false}          | ${1}              | ${false}
      ${false}            | ${true}           | ${1}              | ${false}
    `(
      'given alertFieldsProvided: $alertFieldsProvided, multiIntegrations: $multiIntegrations, integrationOption: $integrationOption, visible: $visible',
      ({ alertFieldsProvided, multiIntegrations, integrationOption, visible }) => {
        const visibleMsg = visible ? 'rendered' : 'not rendered';
        const alertFieldsMsg = alertFieldsProvided ? 'provided' : 'not provided';
        const integrationType = integrationOption === 1 ? typeSet.http : typeSet.prometheus;
        const multiIntegrationsEnabled = multiIntegrations ? 'enabled' : 'not enabled';

        it(`is ${visibleMsg} when multiIntegrations are ${multiIntegrationsEnabled}, integration type is ${integrationType} and alert fields are ${alertFieldsMsg}`, async () => {
          await createComponent({
            multiIntegrations,
            props: {
              alertFields: alertFieldsProvided ? alertFields : [],
            },
          });
          await selectOptionAtIndex(integrationOption);

          expect(findMappingBuilder().exists()).toBe(visible);
        });
      },
    );
  });

  describe('Form validation', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('should not be able to submit when no integration type is selected', async () => {
      await selectOptionAtIndex(0);

      expect(findSubmitButton().attributes('disabled')).toBeDefined();
    });

    it('should not be able to submit when HTTP integration form is invalid', async () => {
      await selectOptionAtIndex(1);
      await findFormFields().at(0).vm.$emit('input', '');
      expect(findSubmitButton().attributes('disabled')).toBeDefined();
    });

    it('should be able to submit when HTTP integration  form is valid', async () => {
      await selectOptionAtIndex(1);
      await findFormFields().at(0).vm.$emit('input', 'Name');
      expect(findSubmitButton().attributes('disabled')).toBe(undefined);
    });

    it('should be able to submit when Prometheus integration  form is valid', async () => {
      await selectOptionAtIndex(2);

      expect(findSubmitButton().attributes('disabled')).toBe(undefined);
    });

    it('should be able to submit when form is dirty', async () => {
      const currentIntegration = { type: typeSet.http, name: 'Existing integration' };
      await createComponent({ currentIntegration });

      await findFormFields().at(0).vm.$emit('input', 'Updated name');
      expect(findSubmitButton().attributes('disabled')).toBe(undefined);
    });

    it('should not be able to submit when form is pristine', async () => {
      const currentIntegration = { type: typeSet.http, name: 'Existing integration' };
      await createComponent({ currentIntegration });
      expect(findSubmitButton().attributes('disabled')).toBeDefined();
    });

    it('should disable submit button after click on validation failure', async () => {
      await selectOptionAtIndex(1);
      await findSubmitButton().trigger('click');

      expect(findSubmitButton().attributes('disabled')).toBeDefined();
    });

    it('should scroll to invalid field on validation failure', async () => {
      await selectOptionAtIndex(1);
      await findSubmitButton().trigger('click');

      expect(scrollIntoViewMock).toHaveBeenCalledWith({ behavior: 'smooth', block: 'center' });
    });
  });
});
