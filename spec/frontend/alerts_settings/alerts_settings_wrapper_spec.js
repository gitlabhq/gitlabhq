import VueApollo from 'vue-apollo';
import { mount, createLocalVue } from '@vue/test-utils';
import createMockApollo from 'jest/helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { GlLoadingIcon } from '@gitlab/ui';
import AlertsSettingsWrapper from '~/alerts_settings/components/alerts_settings_wrapper.vue';
import AlertsSettingsFormOld from '~/alerts_settings/components/alerts_settings_form_old.vue';
import AlertsSettingsFormNew from '~/alerts_settings/components/alerts_settings_form_new.vue';
import IntegrationsList from '~/alerts_settings/components/alerts_integrations_list.vue';
import getIntegrationsQuery from '~/alerts_settings/graphql/queries/get_integrations.query.graphql';
import createHttpIntegrationMutation from '~/alerts_settings/graphql/mutations/create_http_integration.mutation.graphql';
import createPrometheusIntegrationMutation from '~/alerts_settings/graphql/mutations/create_prometheus_integration.mutation.graphql';
import updateHttpIntegrationMutation from '~/alerts_settings/graphql/mutations/update_http_integration.mutation.graphql';
import updatePrometheusIntegrationMutation from '~/alerts_settings/graphql/mutations/update_prometheus_integration.mutation.graphql';
import destroyHttpIntegrationMutation from '~/alerts_settings/graphql/mutations/destroy_http_integration.mutation.graphql';
import resetHttpTokenMutation from '~/alerts_settings/graphql/mutations/reset_http_token.mutation.graphql';
import resetPrometheusTokenMutation from '~/alerts_settings/graphql/mutations/reset_prometheus_token.mutation.graphql';
import { typeSet } from '~/alerts_settings/constants';
import {
  ADD_INTEGRATION_ERROR,
  RESET_INTEGRATION_TOKEN_ERROR,
  UPDATE_INTEGRATION_ERROR,
  INTEGRATION_PAYLOAD_TEST_ERROR,
} from '~/alerts_settings/utils/error_messages';
import createFlash from '~/flash';
import { defaultAlertSettingsConfig } from './util';
import mockIntegrations from './mocks/integrations.json';
import {
  createHttpVariables,
  updateHttpVariables,
  createPrometheusVariables,
  updatePrometheusVariables,
  ID,
  errorMsg,
  getIntegrationsQueryResponse,
  destroyIntegrationResponse,
  integrationToDestroy,
  destroyIntegrationResponseWithErrors,
} from './mocks/apollo_mock';

jest.mock('~/flash');

const localVue = createLocalVue();

describe('AlertsSettingsWrapper', () => {
  let wrapper;
  let fakeApollo;
  let destroyIntegrationHandler;

  const findLoader = () => wrapper.find(IntegrationsList).find(GlLoadingIcon);
  const findIntegrations = () => wrapper.find(IntegrationsList).findAll('table tbody tr');

  async function destroyHttpIntegration(localWrapper) {
    await jest.runOnlyPendingTimers();
    await localWrapper.vm.$nextTick();

    localWrapper
      .find(IntegrationsList)
      .vm.$emit('delete-integration', { id: integrationToDestroy.id });
  }

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

  function createComponentWithApollo({
    destroyHandler = jest.fn().mockResolvedValue(destroyIntegrationResponse),
  } = {}) {
    localVue.use(VueApollo);
    destroyIntegrationHandler = destroyHandler;

    const requestHandlers = [
      [getIntegrationsQuery, jest.fn().mockResolvedValue(getIntegrationsQueryResponse)],
      [destroyHttpIntegrationMutation, destroyIntegrationHandler],
    ];

    fakeApollo = createMockApollo(requestHandlers);

    wrapper = mount(AlertsSettingsWrapper, {
      localVue,
      apolloProvider: fakeApollo,
      provide: {
        ...defaultAlertSettingsConfig,
        glFeatures: { httpIntegrationsList: true },
      },
    });
  }

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

    it('shows an error alert when integration creation fails ', async () => {
      createComponent({
        data: { integrations: { list: mockIntegrations }, currentIntegration: mockIntegrations[0] },
        provide: { glFeatures: { httpIntegrationsList: true } },
        loading: false,
      });

      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue(ADD_INTEGRATION_ERROR);
      wrapper.find(AlertsSettingsFormNew).vm.$emit('create-new-integration', {});

      await waitForPromises();

      expect(createFlash).toHaveBeenCalledWith({ message: ADD_INTEGRATION_ERROR });
    });

    it('shows an error alert when integration token reset fails ', async () => {
      createComponent({
        data: { integrations: { list: mockIntegrations }, currentIntegration: mockIntegrations[0] },
        provide: { glFeatures: { httpIntegrationsList: true } },
        loading: false,
      });

      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue(RESET_INTEGRATION_TOKEN_ERROR);

      wrapper.find(AlertsSettingsFormNew).vm.$emit('reset-token', {});

      await waitForPromises();
      expect(createFlash).toHaveBeenCalledWith({ message: RESET_INTEGRATION_TOKEN_ERROR });
    });

    it('shows an error alert when integration update fails ', async () => {
      createComponent({
        data: { integrations: { list: mockIntegrations }, currentIntegration: mockIntegrations[0] },
        provide: { glFeatures: { httpIntegrationsList: true } },
        loading: false,
      });

      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue(errorMsg);

      wrapper.find(AlertsSettingsFormNew).vm.$emit('update-integration', {});

      await waitForPromises();
      expect(createFlash).toHaveBeenCalledWith({ message: UPDATE_INTEGRATION_ERROR });
    });

    it('shows an error alert when integration test payload fails ', async () => {
      createComponent({
        data: { integrations: { list: mockIntegrations }, currentIntegration: mockIntegrations[0] },
        provide: { glFeatures: { httpIntegrationsList: true } },
        loading: false,
      });

      wrapper.find(AlertsSettingsFormNew).vm.$emit('test-payload-failure');

      await waitForPromises();
      expect(createFlash).toHaveBeenCalledWith({ message: INTEGRATION_PAYLOAD_TEST_ERROR });
      expect(createFlash).toHaveBeenCalledTimes(1);
    });
  });

  describe('with mocked Apollo client', () => {
    it('has a selection of integrations loaded via the getIntegrationsQuery', async () => {
      createComponentWithApollo();

      await jest.runOnlyPendingTimers();
      await wrapper.vm.$nextTick();

      expect(findIntegrations()).toHaveLength(4);
    });

    it('calls a mutation with correct parameters and destroys a integration', async () => {
      createComponentWithApollo();

      await destroyHttpIntegration(wrapper);

      expect(destroyIntegrationHandler).toHaveBeenCalled();

      await wrapper.vm.$nextTick();

      expect(findIntegrations()).toHaveLength(3);
    });

    it('displays flash if mutation had a recoverable error', async () => {
      createComponentWithApollo({
        destroyHandler: jest.fn().mockResolvedValue(destroyIntegrationResponseWithErrors),
      });

      await destroyHttpIntegration(wrapper);

      await wrapper.vm.$nextTick(); // kick off the DOM update
      await jest.runOnlyPendingTimers(); // kick off the mocked GQL stuff (promises)
      await wrapper.vm.$nextTick(); // kick off the DOM update for flash

      expect(createFlash).toHaveBeenCalledWith({ message: 'Houston, we have a problem' });
    });
  });
});
