import { mount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import AlertsSettingsWrapper from '~/alerts_settings/components/alerts_settings_wrapper.vue';
import AlertsSettingsFormOld from '~/alerts_settings/components/alerts_settings_form_old.vue';
import AlertsSettingsFormNew from '~/alerts_settings/components/alerts_settings_form_new.vue';
import IntegrationsList from '~/alerts_settings/components/alerts_integrations_list.vue';
import { defaultAlertSettingsConfig } from './util';
import mockIntegrations from './mocks/integrations.json';

describe('AlertsSettingsWrapper', () => {
  let wrapper;

  const findLoader = () => wrapper.find(IntegrationsList).find(GlLoadingIcon);
  const findIntegrations = () => wrapper.find(IntegrationsList).findAll('table tbody tr');

  const createComponent = ({ data = {}, provide = {}, loading = false } = {}) => {
    wrapper = mount(AlertsSettingsWrapper, {
      data() {
        return { ...data };
      },
      provide: {
        ...defaultAlertSettingsConfig,
        glFeatures: { httpIntegrationsList: false },
        ...provide,
      },
      mocks: {
        $apollo: {
          query: jest.fn(),
          queries: {
            integrations: {
              loading,
            },
          },
        },
      },
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('with httpIntegrationsList feature flag disabled', () => {
    it('renders data driven alerts integrations list and old form by default', () => {
      createComponent();
      expect(wrapper.find(IntegrationsList).exists()).toBe(true);
      expect(wrapper.find(AlertsSettingsFormOld).exists()).toBe(true);
      expect(wrapper.find(AlertsSettingsFormNew).exists()).toBe(false);
    });
  });

  describe('with httpIntegrationsList feature flag enabled', () => {
    it('renders the GraphQL alerts integrations list and new form', () => {
      createComponent({ provide: { glFeatures: { httpIntegrationsList: true } } });
      expect(wrapper.find(IntegrationsList).exists()).toBe(true);
      expect(wrapper.find(AlertsSettingsFormOld).exists()).toBe(false);
      expect(wrapper.find(AlertsSettingsFormNew).exists()).toBe(true);
    });

    it('uses a loading state inside the IntegrationsList table', () => {
      createComponent({
        data: { integrations: {} },
        provide: { glFeatures: { httpIntegrationsList: true } },
        loading: true,
      });
      expect(wrapper.find(IntegrationsList).exists()).toBe(true);
      expect(findLoader().exists()).toBe(true);
    });

    it('renders the IntegrationsList table using the API data', () => {
      createComponent({
        data: { integrations: { list: mockIntegrations } },
        provide: { glFeatures: { httpIntegrationsList: true } },
        loading: false,
      });
      expect(findLoader().exists()).toBe(false);
      expect(findIntegrations()).toHaveLength(mockIntegrations.length);
    });
  });
});
