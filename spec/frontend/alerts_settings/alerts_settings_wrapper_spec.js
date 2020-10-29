import { shallowMount } from '@vue/test-utils';
import AlertsSettingsWrapper from '~/alerts_settings/components/alerts_settings_wrapper.vue';
import AlertsSettingsFormOld from '~/alerts_settings/components/alerts_settings_form_old.vue';
import AlertsSettingsFormNew from '~/alerts_settings/components/alerts_settings_form_new.vue';
import IntegrationsList from '~/alerts_settings/components/alerts_integrations_list.vue';
import { defaultAlertSettingsConfig } from './util';

jest.mock('~/alerts_settings/services');

describe('AlertsSettingsFormWrapper', () => {
  let wrapper;

  const createComponent = (data = {}, provide = {}) => {
    wrapper = shallowMount(AlertsSettingsWrapper, {
      data() {
        return { ...data };
      },
      provide: {
        ...defaultAlertSettingsConfig,
        glFeatures: { httpIntegrationsList: false },
        ...provide,
      },
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('with default values', () => {
    it('renders alerts integrations list and old form by default', () => {
      createComponent();
      expect(wrapper.find(IntegrationsList).exists()).toBe(true);
      expect(wrapper.find(AlertsSettingsFormOld).exists()).toBe(true);
      expect(wrapper.find(AlertsSettingsFormNew).exists()).toBe(false);
    });

    it('renders alerts integrations list and new form when httpIntegrationsList feature flag is enabled', () => {
      createComponent({}, { glFeatures: { httpIntegrationsList: true } });
      expect(wrapper.find(IntegrationsList).exists()).toBe(true);
      expect(wrapper.find(AlertsSettingsFormOld).exists()).toBe(false);
      expect(wrapper.find(AlertsSettingsFormNew).exists()).toBe(true);
    });
  });
});
