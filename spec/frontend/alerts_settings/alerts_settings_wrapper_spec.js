import { mount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import AlertsSettingsWrapper from '~/alerts_settings/components/alerts_settings_wrapper.vue';
import AlertsSettingsFormOld from '~/alerts_settings/components/alerts_settings_form_old.vue';
import AlertsSettingsFormNew from '~/alerts_settings/components/alerts_settings_form_new.vue';
import IntegrationsList from '~/alerts_settings/components/alerts_integrations_list.vue';
import createHttpIntegrationMutation from '~/alerts_settings/graphql/mutations/create_http_integration.mutation.graphql';
import createPrometheusIntegrationMutation from '~/alerts_settings/graphql/mutations/create_prometheus_integration.mutation.graphql';
import updateHttpIntegrationMutation from '~/alerts_settings/graphql/mutations/update_http_integration.mutation.graphql';
import updatePrometheusIntegrationMutation from '~/alerts_settings/graphql/mutations/update_prometheus_integration.mutation.graphql';
import resetHttpTokenMutation from '~/alerts_settings/graphql/mutations/reset_http_token.mutation.graphql';
import resetPrometheusTokenMutation from '~/alerts_settings/graphql/mutations/reset_prometheus_token.mutation.graphql';
import { typeSet } from '~/alerts_settings/constants';
import createFlash from '~/flash';
import { defaultAlertSettingsConfig } from './util';
import mockIntegrations from './mocks/integrations.json';
import {
  createHttpVariables,
  updateHttpVariables,
  createPrometheusVariables,
  updatePrometheusVariables,
  ID,
} from './mocks/apollo_mock';

jest.mock('~/flash');

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
          mutate: jest.fn(),
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
        data: { integrations: { list: mockIntegrations }, currentIntegration: mockIntegrations[0] },
        provide: { glFeatures: { httpIntegrationsList: true } },
        loading: false,
      });
      expect(findLoader().exists()).toBe(false);
      expect(findIntegrations()).toHaveLength(mockIntegrations.length);
    });

    it('shows an error message when a user cannot create a new integration', () => {
      createComponent({
        data: { integrations: { list: mockIntegrations } },
        provide: { glFeatures: { httpIntegrationsList: true } },
        loading: false,
      });
      expect(findLoader().exists()).toBe(false);
      expect(findIntegrations()).toHaveLength(mockIntegrations.length);
    });

    it('calls `$apollo.mutate` with `createHttpIntegrationMutation`', () => {
      createComponent({
        data: { integrations: { list: mockIntegrations }, currentIntegration: mockIntegrations[0] },
        provide: { glFeatures: { httpIntegrationsList: true } },
        loading: false,
      });

      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({
        data: { createHttpIntegrationMutation: { integration: { id: '1' } } },
      });
      wrapper.find(AlertsSettingsFormNew).vm.$emit('create-new-integration', {
        type: typeSet.http,
        variables: createHttpVariables,
      });

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledTimes(1);
      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: createHttpIntegrationMutation,
        update: expect.anything(),
        variables: createHttpVariables,
      });
    });

    it('calls `$apollo.mutate` with `updateHttpIntegrationMutation`', () => {
      createComponent({
        data: { integrations: { list: mockIntegrations }, currentIntegration: mockIntegrations[0] },
        provide: { glFeatures: { httpIntegrationsList: true } },
        loading: false,
      });

      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({
        data: { updateHttpIntegrationMutation: { integration: { id: '1' } } },
      });
      wrapper.find(AlertsSettingsFormNew).vm.$emit('update-integration', {
        type: typeSet.http,
        variables: updateHttpVariables,
      });

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: updateHttpIntegrationMutation,
        variables: updateHttpVariables,
      });
    });

    it('calls `$apollo.mutate` with `resetHttpTokenMutation`', () => {
      createComponent({
        data: { integrations: { list: mockIntegrations }, currentIntegration: mockIntegrations[0] },
        provide: { glFeatures: { httpIntegrationsList: true } },
        loading: false,
      });

      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({
        data: { resetHttpTokenMutation: { integration: { id: '1' } } },
      });
      wrapper.find(AlertsSettingsFormNew).vm.$emit('reset-token', {
        type: typeSet.http,
        variables: { id: ID },
      });

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: resetHttpTokenMutation,
        variables: {
          id: ID,
        },
      });
    });

    it('calls `$apollo.mutate` with `createPrometheusIntegrationMutation`', () => {
      createComponent({
        data: { integrations: { list: mockIntegrations }, currentIntegration: mockIntegrations[0] },
        provide: { glFeatures: { httpIntegrationsList: true } },
        loading: false,
      });

      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({
        data: { createPrometheusIntegrationMutation: { integration: { id: '2' } } },
      });
      wrapper.find(AlertsSettingsFormNew).vm.$emit('create-new-integration', {
        type: typeSet.prometheus,
        variables: createPrometheusVariables,
      });

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledTimes(1);
      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: createPrometheusIntegrationMutation,
        update: expect.anything(),
        variables: createPrometheusVariables,
      });
    });

    it('calls `$apollo.mutate` with `updatePrometheusIntegrationMutation`', () => {
      createComponent({
        data: { integrations: { list: mockIntegrations }, currentIntegration: mockIntegrations[0] },
        provide: { glFeatures: { httpIntegrationsList: true } },
        loading: false,
      });

      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({
        data: { updatePrometheusIntegrationMutation: { integration: { id: '2' } } },
      });
      wrapper.find(AlertsSettingsFormNew).vm.$emit('update-integration', {
        type: typeSet.prometheus,
        variables: updatePrometheusVariables,
      });

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: updatePrometheusIntegrationMutation,
        variables: updatePrometheusVariables,
      });
    });

    it('calls `$apollo.mutate` with `resetPrometheusTokenMutation`', () => {
      createComponent({
        data: { integrations: { list: mockIntegrations }, currentIntegration: mockIntegrations[0] },
        provide: { glFeatures: { httpIntegrationsList: true } },
        loading: false,
      });

      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({
        data: { resetPrometheusTokenMutation: { integration: { id: '1' } } },
      });
      wrapper.find(AlertsSettingsFormNew).vm.$emit('reset-token', {
        type: typeSet.prometheus,
        variables: { id: ID },
      });

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: resetPrometheusTokenMutation,
        variables: {
          id: ID,
        },
      });
    });

    it('shows error alert when integration creation fails ', async () => {
      const errorMsg = 'Something went wrong';
      createComponent({
        data: { integrations: { list: mockIntegrations }, currentIntegration: mockIntegrations[0] },
        provide: { glFeatures: { httpIntegrationsList: true } },
        loading: false,
      });

      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue(errorMsg);
      wrapper.find(AlertsSettingsFormNew).vm.$emit('create-new-integration', {});

      setImmediate(() => {
        expect(createFlash).toHaveBeenCalledWith({ message: errorMsg });
      });
    });

    it('shows error alert when integration token reset fails ', () => {
      const errorMsg = 'Something went wrong';
      createComponent({
        data: { integrations: { list: mockIntegrations }, currentIntegration: mockIntegrations[0] },
        provide: { glFeatures: { httpIntegrationsList: true } },
        loading: false,
      });

      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue(errorMsg);

      wrapper.find(AlertsSettingsFormNew).vm.$emit('reset-token', {});

      setImmediate(() => {
        expect(createFlash).toHaveBeenCalledWith({ message: errorMsg });
      });
    });

    it('shows error alert when integration update fails ', () => {
      const errorMsg = 'Something went wrong';
      createComponent({
        data: { integrations: { list: mockIntegrations }, currentIntegration: mockIntegrations[0] },
        provide: { glFeatures: { httpIntegrationsList: true } },
        loading: false,
      });

      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue(errorMsg);

      wrapper.find(AlertsSettingsFormNew).vm.$emit('update-integration', {});

      setImmediate(() => {
        expect(createFlash).toHaveBeenCalledWith({ message: errorMsg });
      });
    });
  });
});
