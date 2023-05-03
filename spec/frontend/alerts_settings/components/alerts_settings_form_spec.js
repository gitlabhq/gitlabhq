import {
  GlForm,
  GlFormSelect,
  GlFormInput,
  GlToggle,
  GlFormTextarea,
  GlTab,
  GlLink,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import MappingBuilder from '~/alerts_settings/components/alert_mapping_builder.vue';
import AlertsSettingsForm from '~/alerts_settings/components/alerts_settings_form.vue';
import { typeSet } from '~/alerts_settings/constants';
import alertFields from '../mocks/alert_fields.json';
import parsedMapping from '../mocks/parsed_mapping.json';

const scrollIntoViewMock = jest.fn();
HTMLElement.prototype.scrollIntoView = scrollIntoViewMock;

describe('AlertsSettingsForm', () => {
  let wrapper;
  const mockToastShow = jest.fn();

  const createComponent = ({ data = {}, props = {}, multiIntegrations = true } = {}) => {
    wrapper = extendedWrapper(
      mount(AlertsSettingsForm, {
        data() {
          return { ...data };
        },
        propsData: {
          loading: false,
          canAddIntegration: true,
          ...props,
        },
        provide: {
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
      }),
    );
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findSelect = () => wrapper.findComponent(GlFormSelect);
  const findFormFields = () => wrapper.findAllComponents(GlFormInput);
  const findFormToggle = () => wrapper.findComponent(GlToggle);
  const findSamplePayloadSection = () => wrapper.findByTestId('sample-payload-section');
  const findMappingBuilder = () => wrapper.findComponent(MappingBuilder);
  const findSubmitButton = () => wrapper.findByTestId('integration-form-submit');
  const findMultiSupportText = () => wrapper.findByTestId('multi-integrations-not-supported');
  const findJsonTestSubmit = () => wrapper.findByTestId('send-test-alert');
  const findJsonTextArea = () => wrapper.find(`[id = "test-payload"]`);
  const findActionBtn = () => wrapper.findByTestId('payload-action-btn');
  const findTabs = () => wrapper.findAllComponents(GlTab);

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  const selectOptionAtIndex = async (index) => {
    const options = findSelect().findAll('option');
    await options.at(index).setSelected();
  };

  const enableIntegration = (index, value) => {
    findFormFields().at(index).setValue(value);
    findFormToggle().vm.$emit('change', true);
  };

  describe('with default values', () => {
    beforeEach(() => {
      createComponent();
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

    it('disables the dropdown and shows help text when multi integrations are not supported', () => {
      createComponent({ props: { canAddIntegration: false } });
      expect(findSelect().attributes('disabled')).toBeDefined();
      expect(findMultiSupportText().exists()).toBe(true);
    });

    it('hides the name input when the selected value is prometheus', async () => {
      createComponent();
      await selectOptionAtIndex(2);
      expect(findFormFields().at(0).attributes('id')).not.toBe('name-integration');
    });

    it('verify pricing link url', () => {
      createComponent({ props: { canAddIntegration: false } });
      const link = findMultiSupportText().findComponent(GlLink);
      expect(link.attributes('href')).toMatch(/https:\/\/about.gitlab.(com|cn)\/pricing/);
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
      it('create with custom mapping', async () => {
        createComponent({
          multiIntegrations: true,
          props: { alertFields },
        });

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

      it('update', () => {
        createComponent({
          data: {
            integrationForm: { id: '1', name: 'Test integration pre', type: typeSet.http },
            currentIntegration: { id: '1' },
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

        submitBtn.trigger('click');
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
        createComponent();
        await selectOptionAtIndex(2);
        const apiUrl = 'https://test.com';
        enableIntegration(0, apiUrl);
        const submitBtn = findSubmitButton();
        expect(submitBtn.exists()).toBe(true);
        expect(submitBtn.text()).toBe('Save integration');

        findForm().trigger('submit');

        expect(wrapper.emitted('create-new-integration')[0][0]).toMatchObject({
          type: typeSet.prometheus,
          variables: { apiUrl, active: true },
        });
      });

      it('update', () => {
        createComponent({
          data: {
            integrationForm: { id: '1', apiUrl: 'https://test-pre.com', type: typeSet.prometheus },
            currentIntegration: { id: '1' },
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

        expect(wrapper.emitted('update-integration')[0][0]).toMatchObject({
          type: typeSet.prometheus,
          variables: { apiUrl, active: true },
        });
      });
    });
  });

  describe('submitting the integration with a JSON test payload', () => {
    beforeEach(() => {
      createComponent({
        data: {
          currentIntegration: { id: '1', name: 'Test' },
          active: true,
        },
        props: {
          loading: false,
        },
      });
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
    beforeEach(() => {
      createComponent({
        multiIntegrations: true,
        data: {
          integrationForm: { type: typeSet.http },
          currentIntegration: {
            payloadExample: emptySamplePayload,
          },
          active: false,
          resetPayloadAndMappingConfirmed: false,
        },
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
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          currentIntegration: { payloadExample: payload },
          resetPayloadAndMappingConfirmed,
        });

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
          // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
          // eslint-disable-next-line no-restricted-syntax
          wrapper.setData({
            currentIntegration: {
              payloadExample,
            },
            resetPayloadAndMappingConfirmed,
          });
          await nextTick();
          expect(findActionBtn().text()).toBe(caption);
        });
      });
    });

    describe('Parsing payload', () => {
      beforeEach(() => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
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
          createComponent({
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
    beforeEach(() => {
      createComponent();
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

    it('should not be able to submit when Prometheus integration form is invalid', async () => {
      await selectOptionAtIndex(2);
      await findFormFields().at(0).vm.$emit('input', '');

      expect(findSubmitButton().attributes('disabled')).toBeDefined();
    });

    it('should be able to submit when Prometheus integration  form is valid', async () => {
      await selectOptionAtIndex(2);
      await findFormFields().at(0).vm.$emit('input', 'http://valid.url');

      expect(findSubmitButton().attributes('disabled')).toBe(undefined);
    });

    it('should be able to submit when form is dirty', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        currentIntegration: { type: typeSet.http, name: 'Existing integration' },
      });
      await nextTick();
      await findFormFields().at(0).vm.$emit('input', 'Updated name');

      expect(findSubmitButton().attributes('disabled')).toBe(undefined);
    });

    it('should not be able to submit when form is pristine', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        currentIntegration: { type: typeSet.http, name: 'Existing integration' },
      });
      await nextTick();

      expect(findSubmitButton().attributes('disabled')).toBeDefined();
    });

    it('should disable submit button after click on validation failure', async () => {
      await selectOptionAtIndex(1);
      findSubmitButton().trigger('click');
      await nextTick();

      expect(findSubmitButton().attributes('disabled')).toBeDefined();
    });

    it('should scroll to invalid field on validation failure', async () => {
      await selectOptionAtIndex(1);
      findSubmitButton().trigger('click');

      expect(scrollIntoViewMock).toHaveBeenCalledWith({ behavior: 'smooth', block: 'center' });
    });
  });
});
