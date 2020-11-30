import { mount } from '@vue/test-utils';
import {
  GlForm,
  GlFormSelect,
  GlCollapse,
  GlFormInput,
  GlToggle,
  GlFormTextarea,
} from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import AlertsSettingsForm from '~/alerts_settings/components/alerts_settings_form.vue';
import { defaultAlertSettingsConfig } from './util';
import { typeSet } from '~/alerts_settings/constants';

describe('AlertsSettingsFormNew', () => {
  let wrapper;
  const mockToastShow = jest.fn();

  const createComponent = ({
    data = {},
    props = {},
    multipleHttpIntegrationsCustomMapping = false,
  } = {}) => {
    wrapper = mount(AlertsSettingsForm, {
      data() {
        return { ...data };
      },
      propsData: {
        loading: false,
        canAddIntegration: true,
        canManageOpsgenie: true,
        ...props,
      },
      provide: {
        glFeatures: { multipleHttpIntegrationsCustomMapping },
        ...defaultAlertSettingsConfig,
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  };

  const findForm = () => wrapper.find(GlForm);
  const findSelect = () => wrapper.find(GlFormSelect);
  const findFormSteps = () => wrapper.find(GlCollapse);
  const findFormFields = () => wrapper.findAll(GlFormInput);
  const findFormToggle = () => wrapper.find(GlToggle);
  const findTestPayloadSection = () => wrapper.find(`[id = "test-integration"]`);
  const findMappingBuilderSection = () => wrapper.find(`[id = "mapping-builder"]`);
  const findSubmitButton = () => wrapper.find(`[type = "submit"]`);
  const findMultiSupportText = () =>
    wrapper.find(`[data-testid="multi-integrations-not-supported"]`);
  const findJsonTestSubmit = () => wrapper.find(`[data-testid="integration-test-and-submit"]`);
  const findJsonTextArea = () => wrapper.find(`[id = "test-payload"]`);
  const findActionBtn = () => wrapper.find(`[data-testid="payload-action-btn"]`);

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('with default values', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the initial template', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });

    it('render the initial form with only an integration type dropdown', () => {
      expect(findForm().exists()).toBe(true);
      expect(findSelect().exists()).toBe(true);
      expect(findMultiSupportText().exists()).toBe(false);
      expect(findFormSteps().attributes('visible')).toBeUndefined();
    });

    it('shows the rest of the form when the dropdown is used', async () => {
      const options = findSelect().findAll('option');
      await options.at(1).setSelected();

      await wrapper.vm.$nextTick();

      expect(
        findFormFields()
          .at(0)
          .isVisible(),
      ).toBe(true);
    });

    it('disabled the dropdown and shows help text when multi integrations are not supported', async () => {
      createComponent({ props: { canAddIntegration: false } });
      expect(findSelect().attributes('disabled')).toBe('disabled');
      expect(findMultiSupportText().exists()).toBe(true);
    });
  });

  describe('submitting integration form', () => {
    it('allows for create-new-integration with the correct form values for HTTP', async () => {
      createComponent({});

      const options = findSelect().findAll('option');
      await options.at(1).setSelected();

      await findFormFields()
        .at(0)
        .setValue('Test integration');
      await findFormToggle().trigger('click');

      await wrapper.vm.$nextTick();

      expect(findSubmitButton().exists()).toBe(true);
      expect(findSubmitButton().text()).toBe('Save integration');

      findForm().trigger('submit');

      await wrapper.vm.$nextTick();

      expect(wrapper.emitted('create-new-integration')).toBeTruthy();
      expect(wrapper.emitted('create-new-integration')[0]).toEqual([
        { type: typeSet.http, variables: { name: 'Test integration', active: true } },
      ]);
    });

    it('allows for create-new-integration with the correct form values for PROMETHEUS', async () => {
      createComponent({});

      const options = findSelect().findAll('option');
      await options.at(2).setSelected();

      await findFormFields()
        .at(0)
        .setValue('Test integration');
      await findFormFields()
        .at(1)
        .setValue('https://test.com');
      await findFormToggle().trigger('click');

      await wrapper.vm.$nextTick();

      expect(findSubmitButton().exists()).toBe(true);
      expect(findSubmitButton().text()).toBe('Save integration');

      findForm().trigger('submit');

      await wrapper.vm.$nextTick();

      expect(wrapper.emitted('create-new-integration')).toBeTruthy();
      expect(wrapper.emitted('create-new-integration')[0]).toEqual([
        { type: typeSet.prometheus, variables: { apiUrl: 'https://test.com', active: true } },
      ]);
    });

    it('allows for update-integration with the correct form values for HTTP', async () => {
      createComponent({
        data: {
          selectedIntegration: typeSet.http,
          currentIntegration: { id: '1', name: 'Test integration pre' },
        },
        props: {
          loading: false,
        },
      });

      await findFormFields()
        .at(0)
        .setValue('Test integration post');
      await findFormToggle().trigger('click');

      await wrapper.vm.$nextTick();

      expect(findSubmitButton().exists()).toBe(true);
      expect(findSubmitButton().text()).toBe('Save integration');

      findForm().trigger('submit');

      await wrapper.vm.$nextTick();

      expect(wrapper.emitted('update-integration')).toBeTruthy();
      expect(wrapper.emitted('update-integration')[0]).toEqual([
        { type: typeSet.http, variables: { name: 'Test integration post', active: true } },
      ]);
    });

    it('allows for update-integration with the correct form values for PROMETHEUS', async () => {
      createComponent({
        data: {
          selectedIntegration: typeSet.prometheus,
          currentIntegration: { id: '1', apiUrl: 'https://test-pre.com' },
        },
        props: {
          loading: false,
        },
      });

      await findFormFields()
        .at(0)
        .setValue('Test integration');
      await findFormFields()
        .at(1)
        .setValue('https://test-post.com');
      await findFormToggle().trigger('click');

      await wrapper.vm.$nextTick();

      expect(findSubmitButton().exists()).toBe(true);
      expect(findSubmitButton().text()).toBe('Save integration');

      findForm().trigger('submit');

      await wrapper.vm.$nextTick();

      expect(wrapper.emitted('update-integration')).toBeTruthy();
      expect(wrapper.emitted('update-integration')[0]).toEqual([
        { type: typeSet.prometheus, variables: { apiUrl: 'https://test-post.com', active: true } },
      ]);
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

      expect(findJsonTestSubmit().exists()).toBe(true);
      expect(findJsonTestSubmit().text()).toBe('Save and test payload');
      expect(findJsonTestSubmit().props('disabled')).toBe(true);
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
    beforeEach(() => {
      createComponent({
        multipleHttpIntegrationsCustomMapping: true,
        props: {
          currentIntegration: {
            type: typeSet.http,
          },
        },
      });
    });

    describe.each`
      active   | resetSamplePayloadConfirmed | disabled
      ${true}  | ${true}                     | ${undefined}
      ${false} | ${true}                     | ${'disabled'}
      ${true}  | ${false}                    | ${'disabled'}
      ${false} | ${false}                    | ${'disabled'}
    `('', ({ active, resetSamplePayloadConfirmed, disabled }) => {
      const payloadResetMsg = resetSamplePayloadConfirmed ? 'was confirmed' : 'was not confirmed';
      const enabledState = disabled === 'disabled' ? 'disabled' : 'enabled';
      const activeState = active ? 'active' : 'not active';

      it(`textarea should be ${enabledState} when payload reset ${payloadResetMsg} and current integration is ${activeState}`, async () => {
        wrapper.setData({
          customMapping: { samplePayload: true },
          active,
          resetSamplePayloadConfirmed,
        });
        await wrapper.vm.$nextTick();
        expect(
          findTestPayloadSection()
            .find(GlFormTextarea)
            .attributes('disabled'),
        ).toBe(disabled);
      });
    });

    describe('action buttons for sample payload', () => {
      describe.each`
        resetSamplePayloadConfirmed | samplePayload | caption
        ${false}                    | ${true}       | ${'Edit payload'}
        ${true}                     | ${false}      | ${'Submit payload'}
        ${true}                     | ${true}       | ${'Submit payload'}
        ${false}                    | ${false}      | ${'Submit payload'}
      `('', ({ resetSamplePayloadConfirmed, samplePayload, caption }) => {
        const samplePayloadMsg = samplePayload ? 'was provided' : 'was not provided';
        const payloadResetMsg = resetSamplePayloadConfirmed ? 'was confirmed' : 'was not confirmed';

        it(`shows ${caption} button when sample payload ${samplePayloadMsg} and payload reset ${payloadResetMsg}`, async () => {
          wrapper.setData({
            selectedIntegration: typeSet.http,
            customMapping: { samplePayload },
            resetSamplePayloadConfirmed,
          });
          await wrapper.vm.$nextTick();
          expect(findActionBtn().text()).toBe(caption);
        });
      });
    });

    describe('Parsing payload', () => {
      it('displays a toast message on successful parse', async () => {
        jest.useFakeTimers();
        wrapper.setData({
          selectedIntegration: typeSet.http,
          customMapping: { samplePayload: false },
        });
        await wrapper.vm.$nextTick();

        findActionBtn().vm.$emit('click');
        jest.advanceTimersByTime(1000);

        await waitForPromises();

        expect(mockToastShow).toHaveBeenCalledWith(
          'Sample payload has been parsed. You can now map the fields.',
        );
      });
    });
  });

  describe('Mapping builder section', () => {
    describe.each`
      featureFlag | integrationOption | visible
      ${true}     | ${1}              | ${true}
      ${true}     | ${2}              | ${false}
      ${false}    | ${1}              | ${false}
      ${false}    | ${2}              | ${false}
    `('', ({ featureFlag, integrationOption, visible }) => {
      const visibleMsg = visible ? 'is rendered' : 'is not rendered';
      const featureFlagMsg = featureFlag ? 'is enabled' : 'is disabled';
      const integrationType = integrationOption === 1 ? typeSet.http : typeSet.prometheus;

      it(`${visibleMsg} when multipleHttpIntegrationsCustomMapping feature flag ${featureFlagMsg} and integration type is ${integrationType}`, async () => {
        createComponent({ multipleHttpIntegrationsCustomMapping: featureFlag });
        const options = findSelect().findAll('option');
        options.at(integrationOption).setSelected();
        await wrapper.vm.$nextTick();
        expect(findMappingBuilderSection().exists()).toBe(visible);
      });
    });
  });
});
