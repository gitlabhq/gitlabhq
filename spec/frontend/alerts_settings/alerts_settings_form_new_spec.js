import { mount } from '@vue/test-utils';
import { GlForm, GlFormSelect, GlCollapse, GlFormInput, GlToggle } from '@gitlab/ui';
import AlertsSettingsForm from '~/alerts_settings/components/alerts_settings_form_new.vue';
import { defaultAlertSettingsConfig } from './util';
import { typeSet } from '~/alerts_settings/constants';

describe('AlertsSettingsFormNew', () => {
  let wrapper;

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
        ...props,
      },
      provide: {
        glFeatures: { multipleHttpIntegrationsCustomMapping },
        ...defaultAlertSettingsConfig,
      },
    });
  };

  const findForm = () => wrapper.find(GlForm);
  const findSelect = () => wrapper.find(GlFormSelect);
  const findFormSteps = () => wrapper.find(GlCollapse);
  const findFormFields = () => wrapper.findAll(GlFormInput);
  const findFormToggle = () => wrapper.find(GlToggle);
  const findMappingBuilderSection = () => wrapper.find(`[id = "mapping-builder"]`);
  const findSubmitButton = () => wrapper.find(`[type = "submit"]`);
  const findMultiSupportText = () =>
    wrapper.find(`[data-testid="multi-integrations-not-supported"]`);

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
        },
        props: {
          currentIntegration: { id: '1', name: 'Test integration pre' },
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
        },
        props: {
          currentIntegration: { id: '1', apiUrl: 'https://test-pre.com' },
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

  describe('Mapping builder section', () => {
    beforeEach(() => {
      createComponent({});
    });

    it('should NOT render when feature flag disabled', () => {
      expect(findMappingBuilderSection().exists()).toBe(false);
    });

    it('should render when feature flag is enabled', () => {
      createComponent({ multipleHttpIntegrationsCustomMapping: true });
      expect(findMappingBuilderSection().exists()).toBe(true);
    });
  });
});
