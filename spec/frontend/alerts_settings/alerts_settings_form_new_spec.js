import { shallowMount } from '@vue/test-utils';
import { GlForm, GlFormSelect, GlCollapse, GlFormInput } from '@gitlab/ui';
import AlertsSettingsForm from '~/alerts_settings/components/alerts_settings_form_new.vue';
import { defaultAlertSettingsConfig } from './util';

describe('AlertsSettingsFormNew', () => {
  let wrapper;

  const createComponent = (
    { methods } = {},
    data,
    multipleHttpIntegrationsCustomMapping = false,
  ) => {
    wrapper = shallowMount(AlertsSettingsForm, {
      data() {
        return { ...data };
      },
      provide: {
        glFeatures: { multipleHttpIntegrationsCustomMapping },
        ...defaultAlertSettingsConfig,
      },
      methods,
      stubs: { GlCollapse, GlFormInput },
    });
  };

  const findForm = () => wrapper.find(GlForm);
  const findSelect = () => wrapper.find(GlFormSelect);
  const findFormSteps = () => wrapper.find(GlCollapse);
  const findFormName = () => wrapper.find(GlFormInput);
  const findMappingBuilderSection = () => wrapper.find(`[id = "mapping-builder"]`);

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
      expect(findFormSteps().attributes('visible')).toBeUndefined();
    });

    it('shows the rest of the form when the dropdown is used', async () => {
      findSelect().vm.$emit('change', 'prometheus');

      await wrapper.vm.$nextTick();

      expect(findFormName().isVisible()).toBe(true);
    });
  });

  describe('Mapping builder section', () => {
    beforeEach(() => {
      createComponent({}, {});
    });

    it('should NOT render when feature flag disabled', () => {
      expect(findMappingBuilderSection().exists()).toBe(false);
    });

    it('should render when feature flag is enabled', () => {
      createComponent({}, {}, true);
      expect(findMappingBuilderSection().exists()).toBe(true);
    });
  });
});
