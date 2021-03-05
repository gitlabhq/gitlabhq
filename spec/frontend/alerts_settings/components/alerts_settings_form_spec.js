import { GlForm, GlFormSelect, GlFormInput, GlToggle, GlFormTextarea, GlTab } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import MappingBuilder from '~/alerts_settings/components/alert_mapping_builder.vue';
import AlertsSettingsForm from '~/alerts_settings/components/alerts_settings_form.vue';
import { typeSet } from '~/alerts_settings/constants';
import alertFields from '../mocks/alert_fields.json';
import parsedMapping from '../mocks/parsed_mapping.json';
import { defaultAlertSettingsConfig } from './util';

describe('AlertsSettingsForm', () => {
  let wrapper;
  const mockToastShow = jest.fn();

  const createComponent = ({
    data = {},
    props = {},
    multipleHttpIntegrationsCustomMapping = false,
    multiIntegrations = true,
  } = {}) => {
    wrapper = mount(AlertsSettingsForm, {
      data() {
        return { ...data };
      },
      propsData: {
        loading: false,
        canAddIntegration: true,
        ...props,
      },
      provide: {
        ...defaultAlertSettingsConfig,
        glFeatures: { multipleHttpIntegrationsCustomMapping },
        multiIntegrations,
      },
      mocks: {
        $apollo: {
          query: jest.fn(),
        },
        $toast: {
          show: mockToastShow,
        },
      },
    });
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findSelect = () => wrapper.findComponent(GlFormSelect);
  const findFormFields = () => wrapper.findAllComponents(GlFormInput);
  const findFormToggle = () => wrapper.findComponent(GlToggle);
  const findSamplePayloadSection = () => wrapper.find('[data-testid="sample-payload-section"]');
  const findMappingBuilderSection = () => wrapper.find(`[id = "mapping-builder"]`);
  const findMappingBuilder = () => wrapper.findComponent(MappingBuilder);
  const findSubmitButton = () => wrapper.find(`[type = "submit"]`);
  const findMultiSupportText = () =>
    wrapper.find(`[data-testid="multi-integrations-not-supported"]`);
  const findJsonTestSubmit = () => wrapper.find(`[data-testid="send-test-alert"]`);
  const findJsonTextArea = () => wrapper.find(`[id = "test-payload"]`);
  const findActionBtn = () => wrapper.find(`[data-testid="payload-action-btn"]`);
  const findTabs = () => wrapper.findAllComponents(GlTab);

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const selectOptionAtIndex = async (index) => {
    const options = findSelect().findAll('option');
    await options.at(index).setSelected();
  };

  const enableIntegration = (index, value) => {
    findFormFields().at(index).setValue(value);
    findFormToggle().trigger('click');
  };

  describe('with default values', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the initial template', () => {
      expect(wrapper.element).toMatchSnapshot();
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
      createComponent({ props: { canAddIntegration: false } });
      expect(findSelect().attributes('disabled')).toBe('disabled');
      expect(findMultiSupportText().exists()).toBe(true);
    });

    it('hides the name input when the selected value is prometheus', async () => {
      createComponent();
      await selectOptionAtIndex(2);
      expect(findFormFields().at(0).attributes('id')).not.toBe('name-integration');
    });

    describe('form tabs', () => {
      it('renders 3 tabs', () => {
        expect(findTabs()).toHaveLength(3);
      });

      it('only first tab is enabled on integration create', () => {
        createComponent({
          data: {
            currentIntegration: null,
          },
        });
        const tabs = findTabs();
        expect(tabs.at(0).find('[role="tabpanel"]').classes('disabled')).toBe(false);
        expect(tabs.at(1).find('[role="tabpanel"]').classes('disabled')).toBe(true);
        expect(tabs.at(2).find('[role="tabpanel"]').classes('disabled')).toBe(true);
      });

      it('all tabs are enabled on integration edit', () => {
        createComponent({
          data: {
            currentIntegration: { id: 1 },
          },
        });
        const tabs = findTabs();
        expect(tabs.at(0).find('[role="tabpanel"]').classes('disabled')).toBe(false);
        expect(tabs.at(1).find('[role="tabpanel"]').classes('disabled')).toBe(false);
        expect(tabs.at(2).find('[role="tabpanel"]').classes('disabled')).toBe(false);
      });
    });
  });

  describe('submitting integration form', () => {
    describe('HTTP', () => {
      it('create', async () => {
        createComponent();

        const integrationName = 'Test integration';
        await selectOptionAtIndex(1);
        enableIntegration(0, integrationName);

        const submitBtn = findSubmitButton();
        expect(submitBtn.exists()).toBe(true);
        expect(submitBtn.text()).toBe('Save integration');

        findForm().trigger('submit');

        expect(wrapper.emitted('create-new-integration')[0]).toEqual([
          { type: typeSet.http, variables: { name: integrationName, active: true } },
        ]);
      });

      it('create with custom mapping', async () => {
        createComponent({
          multipleHttpIntegrationsCustomMapping: true,
          multiIntegrations: true,
          props: { alertFields },
        });

        const integrationName = 'Test integration';
        await selectOptionAtIndex(1);

        enableIntegration(0, integrationName);

        const sampleMapping = parsedMapping.payloadAttributeMappings;
        findMappingBuilder().vm.$emit('onMappingUpdate', sampleMapping);
        findForm().trigger('submit');

        expect(wrapper.emitted('create-new-integration')[0]).toEqual([
          {
            type: typeSet.http,
            variables: {
              name: integrationName,
              active: true,
              payloadAttributeMappings: sampleMapping,
              payloadExample: '{}',
            },
          },
        ]);
      });

      it('update', () => {
        createComponent({
          data: {
            selectedIntegration: typeSet.http,
            currentIntegration: { id: '1', name: 'Test integration pre' },
          },
          props: {
            loading: false,
          },
        });
        const updatedIntegrationName = 'Test integration post';
        enableIntegration(0, updatedIntegrationName);

        const submitBtn = findSubmitButton();
        expect(submitBtn.exists()).toBe(true);
        expect(submitBtn.text()).toBe('Save integration');

        findForm().trigger('submit');

        expect(wrapper.emitted('update-integration')[0]).toEqual([
          { type: typeSet.http, variables: { name: updatedIntegrationName, active: true } },
        ]);
      });
    });

    describe('PROMETHEUS', () => {
      it('create', async () => {
        createComponent();
        await selectOptionAtIndex(2);
        const apiUrl = 'https://test.com';
        enableIntegration(0, apiUrl);
        const submitBtn = findSubmitButton();
        expect(submitBtn.exists()).toBe(true);
        expect(submitBtn.text()).toBe('Save integration');

        findForm().trigger('submit');

        expect(wrapper.emitted('create-new-integration')[0]).toEqual([
          { type: typeSet.prometheus, variables: { apiUrl, active: true } },
        ]);
      });

      it('update', () => {
        createComponent({
          data: {
            selectedIntegration: typeSet.prometheus,
            currentIntegration: { id: '1', apiUrl: 'https://test-pre.com' },
          },
          props: {
            loading: false,
          },
        });

        const apiUrl = 'https://test-post.com';
        enableIntegration(0, apiUrl);

        const submitBtn = findSubmitButton();
        expect(submitBtn.exists()).toBe(true);
        expect(submitBtn.text()).toBe('Save integration');

        findForm().trigger('submit');

        expect(wrapper.emitted('update-integration')[0]).toEqual([
          { type: typeSet.prometheus, variables: { apiUrl, active: true } },
        ]);
      });
    });
  });

  describe('submitting the integration with a JSON test payload', () => {
    beforeEach(() => {
      createComponent({
        data: {
          selectedIntegration: typeSet.http,
          currentIntegration: { id: '1', name: 'Test' },
          active: true,
        },
        props: {
          loading: false,
        },
      });
    });

    it('should not allow a user to test invalid JSON', async () => {
      jest.useFakeTimers();
      await findJsonTextArea().setValue('Invalid JSON');

      jest.runAllTimers();
      await wrapper.vm.$nextTick();

      const jsonTestSubmit = findJsonTestSubmit();
      expect(jsonTestSubmit.exists()).toBe(true);
      expect(jsonTestSubmit.text()).toBe('Send');
      expect(jsonTestSubmit.props('disabled')).toBe(true);
    });

    it('should allow for the form to be automatically saved if the test payload is successfully submitted', async () => {
      jest.useFakeTimers();
      await findJsonTextArea().setValue('{ "value": "value" }');

      jest.runAllTimers();
      await wrapper.vm.$nextTick();
      expect(findJsonTestSubmit().props('disabled')).toBe(false);
    });
  });

  describe('Test payload section for HTTP integration', () => {
    const validSamplePayload = JSON.stringify(alertFields);
    const emptySamplePayload = '{}';

    beforeEach(() => {
      createComponent({
        multipleHttpIntegrationsCustomMapping: true,
        data: {
          currentIntegration: {
            type: typeSet.http,
            payloadExample: validSamplePayload,
            payloadAttributeMappings: [],
          },
          active: false,
          resetPayloadAndMappingConfirmed: false,
        },
        props: { alertFields },
      });
    });

    describe.each`
      active   | resetPayloadAndMappingConfirmed | disabled
      ${true}  | ${true}                         | ${undefined}
      ${false} | ${true}                         | ${'disabled'}
      ${true}  | ${false}                        | ${'disabled'}
      ${false} | ${false}                        | ${'disabled'}
    `('', ({ active, resetPayloadAndMappingConfirmed, disabled }) => {
      const payloadResetMsg = resetPayloadAndMappingConfirmed
        ? 'was confirmed'
        : 'was not confirmed';
      const enabledState = disabled === 'disabled' ? 'disabled' : 'enabled';
      const activeState = active ? 'active' : 'not active';

      it(`textarea should be ${enabledState} when payload reset ${payloadResetMsg} and current integration is ${activeState}`, async () => {
        wrapper.setData({
          selectedIntegration: typeSet.http,
          active,
          resetPayloadAndMappingConfirmed,
        });
        await wrapper.vm.$nextTick();
        expect(findSamplePayloadSection().find(GlFormTextarea).attributes('disabled')).toBe(
          disabled,
        );
      });
    });

    describe('action buttons for sample payload', () => {
      describe.each`
        resetPayloadAndMappingConfirmed | payloadExample        | caption
        ${false}                        | ${validSamplePayload} | ${'Edit payload'}
        ${true}                         | ${emptySamplePayload} | ${'Parse payload for custom mapping'}
        ${true}                         | ${validSamplePayload} | ${'Parse payload for custom mapping'}
        ${false}                        | ${emptySamplePayload} | ${'Parse payload for custom mapping'}
      `('', ({ resetPayloadAndMappingConfirmed, payloadExample, caption }) => {
        const samplePayloadMsg = payloadExample ? 'was provided' : 'was not provided';
        const payloadResetMsg = resetPayloadAndMappingConfirmed
          ? 'was confirmed'
          : 'was not confirmed';

        it(`shows ${caption} button when sample payload ${samplePayloadMsg} and payload reset ${payloadResetMsg}`, async () => {
          wrapper.setData({
            selectedIntegration: typeSet.http,
            currentIntegration: {
              payloadExample,
              type: typeSet.http,
              active: true,
              payloadAttributeMappings: [],
            },
            resetPayloadAndMappingConfirmed,
          });
          await wrapper.vm.$nextTick();
          expect(findActionBtn().text()).toBe(caption);
        });
      });
    });

    describe('Parsing payload', () => {
      beforeEach(() => {
        wrapper.setData({
          selectedIntegration: typeSet.http,
          resetPayloadAndMappingConfirmed: true,
        });
      });

      it('displays a toast message on successful parse', async () => {
        jest.spyOn(wrapper.vm.$apollo, 'query').mockResolvedValue({
          data: {
            project: { alertManagementPayloadFields: [] },
          },
        });
        findActionBtn().vm.$emit('click');

        await waitForPromises();

        expect(mockToastShow).toHaveBeenCalledWith(
          'Sample payload has been parsed. You can now map the fields.',
        );
      });

      it('displays an error message under payload field on unsuccessful parse', async () => {
        const errorMessage = 'Error parsing paylod';
        jest.spyOn(wrapper.vm.$apollo, 'query').mockRejectedValue({ message: errorMessage });
        findActionBtn().vm.$emit('click');

        await waitForPromises();

        expect(findSamplePayloadSection().find('.invalid-feedback').text()).toBe(errorMessage);
      });
    });
  });

  describe('Mapping builder section', () => {
    describe.each`
      alertFieldsProvided | multiIntegrations | featureFlag | integrationOption | visible
      ${true}             | ${true}           | ${true}     | ${1}              | ${true}
      ${true}             | ${true}           | ${true}     | ${2}              | ${false}
      ${true}             | ${true}           | ${false}    | ${1}              | ${false}
      ${true}             | ${true}           | ${false}    | ${2}              | ${false}
      ${true}             | ${false}          | ${true}     | ${1}              | ${false}
      ${false}            | ${true}           | ${true}     | ${1}              | ${false}
    `('', ({ alertFieldsProvided, multiIntegrations, featureFlag, integrationOption, visible }) => {
      const visibleMsg = visible ? 'is rendered' : 'is not rendered';
      const featureFlagMsg = featureFlag ? 'is enabled' : 'is disabled';
      const alertFieldsMsg = alertFieldsProvided ? 'are provided' : 'are not provided';
      const integrationType = integrationOption === 1 ? typeSet.http : typeSet.prometheus;

      it(`${visibleMsg} when multipleHttpIntegrationsCustomMapping feature flag ${featureFlagMsg} and integration type is ${integrationType} and alert fields ${alertFieldsMsg}`, async () => {
        createComponent({
          multipleHttpIntegrationsCustomMapping: featureFlag,
          multiIntegrations,
          props: {
            alertFields: alertFieldsProvided ? alertFields : [],
          },
        });
        await selectOptionAtIndex(integrationOption);

        expect(findMappingBuilderSection().exists()).toBe(visible);
      });
    });
  });
});
