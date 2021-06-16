import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createHttpIntegrationMutation from 'ee_else_ce/alerts_settings/graphql/mutations/create_http_integration.mutation.graphql';
import updateHttpIntegrationMutation from 'ee_else_ce/alerts_settings/graphql/mutations/update_http_integration.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useMockIntersectionObserver } from 'helpers/mock_dom_observer';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import IntegrationsList from '~/alerts_settings/components/alerts_integrations_list.vue';
import AlertsSettingsForm from '~/alerts_settings/components/alerts_settings_form.vue';
import AlertsSettingsWrapper from '~/alerts_settings/components/alerts_settings_wrapper.vue';
import { typeSet, i18n } from '~/alerts_settings/constants';
import createPrometheusIntegrationMutation from '~/alerts_settings/graphql/mutations/create_prometheus_integration.mutation.graphql';
import destroyHttpIntegrationMutation from '~/alerts_settings/graphql/mutations/destroy_http_integration.mutation.graphql';
import resetHttpTokenMutation from '~/alerts_settings/graphql/mutations/reset_http_token.mutation.graphql';
import resetPrometheusTokenMutation from '~/alerts_settings/graphql/mutations/reset_prometheus_token.mutation.graphql';
import updateCurrentHttpIntegrationMutation from '~/alerts_settings/graphql/mutations/update_current_http_integration.mutation.graphql';
import updateCurrentPrometheusIntegrationMutation from '~/alerts_settings/graphql/mutations/update_current_prometheus_integration.mutation.graphql';
import updatePrometheusIntegrationMutation from '~/alerts_settings/graphql/mutations/update_prometheus_integration.mutation.graphql';
import getHttpIntegrationQuery from '~/alerts_settings/graphql/queries/get_http_integration.query.graphql';
import getIntegrationsQuery from '~/alerts_settings/graphql/queries/get_integrations.query.graphql';
import alertsUpdateService from '~/alerts_settings/services';
import {
  ADD_INTEGRATION_ERROR,
  RESET_INTEGRATION_TOKEN_ERROR,
  UPDATE_INTEGRATION_ERROR,
  INTEGRATION_PAYLOAD_TEST_ERROR,
  INTEGRATION_INACTIVE_PAYLOAD_TEST_ERROR,
  DELETE_INTEGRATION_ERROR,
} from '~/alerts_settings/utils/error_messages';
import createFlash, { FLASH_TYPES } from '~/flash';
import axios from '~/lib/utils/axios_utils';
import httpStatusCodes from '~/lib/utils/http_status';
import {
  createHttpVariables,
  updateHttpVariables,
  createPrometheusVariables,
  updatePrometheusVariables,
  HTTP_ID,
  PROMETHEUS_ID,
  errorMsg,
  getIntegrationsQueryResponse,
  destroyIntegrationResponse,
  integrationToDestroy,
  destroyIntegrationResponseWithErrors,
} from './mocks/apollo_mock';
import mockIntegrations from './mocks/integrations.json';

jest.mock('~/flash');

const localVue = createLocalVue();

describe('AlertsSettingsWrapper', () => {
  let wrapper;
  let fakeApollo;
  let destroyIntegrationHandler;
  useMockIntersectionObserver();

  const httpMappingData = {
    payloadExample: '{"test: : "field"}',
    payloadAttributeMappings: [],
    payloadAlertFields: [],
  };

  const findLoader = () => wrapper.findComponent(IntegrationsList).findComponent(GlLoadingIcon);
  const findIntegrationsList = () => wrapper.findComponent(IntegrationsList);
  const findIntegrations = () => wrapper.find(IntegrationsList).findAll('table tbody tr');
  const findAddIntegrationBtn = () => wrapper.findByTestId('add-integration-btn');
  const findAlertsSettingsForm = () => wrapper.findComponent(AlertsSettingsForm);
  const findAlert = () => wrapper.findComponent(GlAlert);

  async function destroyHttpIntegration(localWrapper) {
    await jest.runOnlyPendingTimers();
    await localWrapper.vm.$nextTick();

    localWrapper
      .find(IntegrationsList)
      .vm.$emit('delete-integration', { id: integrationToDestroy.id });
  }

  async function awaitApolloDomMock() {
    await nextTick(); // kick off the DOM update
    await jest.runOnlyPendingTimers(); // kick off the mocked GQL stuff (promises)
    await nextTick(); // kick off the DOM update for flash
  }

  const createComponent = ({ data = {}, provide = {}, loading = false } = {}) => {
    wrapper = extendedWrapper(
      mount(AlertsSettingsWrapper, {
        data() {
          return { ...data };
        },
        provide: {
          ...provide,
          alertSettings: {
            templates: [],
          },
          service: {},
        },
        mocks: {
          $apollo: {
            mutate: jest.fn(),
            addSmartQuery: jest.fn((_, options) => {
              options.result.call(wrapper.vm);
            }),
            queries: {
              integrations: {
                loading,
              },
            },
          },
        },
      }),
    );
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
        alertSettings: {
          templates: [],
        },
        service: {},
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent({
        data: {
          integrations: mockIntegrations,
          currentIntegration: mockIntegrations[0],
        },
        loading: false,
      });
    });

    it('renders alerts integrations list', () => {
      expect(findLoader().exists()).toBe(false);
      expect(findIntegrations()).toHaveLength(mockIntegrations.length);
    });

    it('renders `Add new integration` button when multiple integrations are supported ', () => {
      createComponent({
        data: {
          integrations: mockIntegrations,
          currentIntegration: mockIntegrations[0],
        },
        provide: {
          multiIntegrations: true,
        },
        loading: false,
      });
      expect(findAddIntegrationBtn().exists()).toBe(true);
    });

    it('does NOT render settings form by default', () => {
      expect(findAlertsSettingsForm().exists()).toBe(false);
    });

    it('hides `add new integration` button and displays setting form on btn click', async () => {
      createComponent({
        data: {
          integrations: mockIntegrations,
          currentIntegration: mockIntegrations[0],
        },
        provide: {
          multiIntegrations: true,
        },
        loading: false,
      });
      const addNewIntegrationBtn = findAddIntegrationBtn();
      expect(addNewIntegrationBtn.exists()).toBe(true);
      await addNewIntegrationBtn.trigger('click');
      expect(findAlertsSettingsForm().exists()).toBe(true);
      expect(addNewIntegrationBtn.exists()).toBe(false);
    });

    it('shows loading indicator inside the IntegrationsList table', () => {
      createComponent({
        data: { integrations: [] },
        loading: true,
      });
      expect(wrapper.find(IntegrationsList).exists()).toBe(true);
      expect(findLoader().exists()).toBe(true);
    });
  });

  describe('Integration updates', () => {
    beforeEach(() => {
      createComponent({
        data: {
          integrations: mockIntegrations,
          currentIntegration: mockIntegrations[0],
          formVisible: true,
        },
        loading: false,
      });
    });

    describe('Create', () => {
      beforeEach(() => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({
          data: { httpIntegrationCreate: { integration: { id: '1' }, errors: [] } },
        });
        findAlertsSettingsForm().vm.$emit('create-new-integration', {
          type: typeSet.http,
          variables: createHttpVariables,
        });
      });

      it('calls `$apollo.mutate` with `createHttpIntegrationMutation`', () => {
        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledTimes(1);
        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
          mutation: createHttpIntegrationMutation,
          update: expect.anything(),
          variables: createHttpVariables,
        });
      });

      it('shows success alert', () => {
        expect(findAlert().exists()).toBe(true);
      });
    });

    it('calls `$apollo.mutate` with `updateHttpIntegrationMutation`', () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({
        data: { updateHttpIntegrationMutation: { integration: { id: '1' } } },
      });
      findAlertsSettingsForm().vm.$emit('update-integration', {
        type: typeSet.http,
        variables: updateHttpVariables,
      });

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: updateHttpIntegrationMutation,
        variables: updateHttpVariables,
      });
    });

    it('calls `$apollo.mutate` with `resetHttpTokenMutation`', () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({
        data: { resetHttpTokenMutation: { integration: { id: '1' } } },
      });
      findAlertsSettingsForm().vm.$emit('reset-token', {
        type: typeSet.http,
        variables: { id: HTTP_ID },
      });

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: resetHttpTokenMutation,
        variables: {
          id: HTTP_ID,
        },
      });
    });

    it('calls `$apollo.mutate` with `createPrometheusIntegrationMutation`', () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({
        data: { createPrometheusIntegrationMutation: { integration: { id: '2' } } },
      });
      findAlertsSettingsForm().vm.$emit('create-new-integration', {
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
        data: {
          integrations: mockIntegrations,
          currentIntegration: mockIntegrations[3],
          formVisible: true,
        },
        loading: false,
      });

      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({
        data: { updatePrometheusIntegrationMutation: { integration: { id: '2' } } },
      });
      findAlertsSettingsForm().vm.$emit('update-integration', {
        type: typeSet.prometheus,
        variables: updatePrometheusVariables,
      });

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: updatePrometheusIntegrationMutation,
        variables: updatePrometheusVariables,
      });
    });

    it('calls `$apollo.mutate` with `resetPrometheusTokenMutation`', () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({
        data: { resetPrometheusTokenMutation: { integration: { id: '1' } } },
      });
      findAlertsSettingsForm().vm.$emit('reset-token', {
        type: typeSet.prometheus,
        variables: { id: PROMETHEUS_ID },
      });

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: resetPrometheusTokenMutation,
        variables: {
          id: PROMETHEUS_ID,
        },
      });
    });

    it('shows an error alert when integration creation fails ', async () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue(ADD_INTEGRATION_ERROR);
      findAlertsSettingsForm().vm.$emit('create-new-integration', {});

      await waitForPromises();

      expect(createFlash).toHaveBeenCalledWith({ message: ADD_INTEGRATION_ERROR });
    });

    it('shows an error alert when integration token reset fails ', async () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue(RESET_INTEGRATION_TOKEN_ERROR);

      findAlertsSettingsForm().vm.$emit('reset-token', {});

      await waitForPromises();
      expect(createFlash).toHaveBeenCalledWith({ message: RESET_INTEGRATION_TOKEN_ERROR });
    });

    it('shows an error alert when integration update fails ', async () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue(errorMsg);

      findAlertsSettingsForm().vm.$emit('update-integration', {});

      await waitForPromises();
      expect(createFlash).toHaveBeenCalledWith({ message: UPDATE_INTEGRATION_ERROR });
    });

    describe('Test alert failure', () => {
      let mock;
      beforeEach(() => {
        mock = new AxiosMockAdapter(axios);
      });
      afterEach(() => {
        mock.restore();
      });

      it('shows an error alert when integration test payload is invalid ', async () => {
        mock.onPost(/(.*)/).replyOnce(httpStatusCodes.UNPROCESSABLE_ENTITY);
        await wrapper.vm.testAlertPayload({ endpoint: '', data: '', token: '' });
        expect(createFlash).toHaveBeenCalledWith({ message: INTEGRATION_PAYLOAD_TEST_ERROR });
        expect(createFlash).toHaveBeenCalledTimes(1);
      });

      it('shows an error alert when integration is not activated ', async () => {
        mock.onPost(/(.*)/).replyOnce(httpStatusCodes.FORBIDDEN);
        await wrapper.vm.testAlertPayload({ endpoint: '', data: '', token: '' });
        expect(createFlash).toHaveBeenCalledWith({
          message: INTEGRATION_INACTIVE_PAYLOAD_TEST_ERROR,
        });
        expect(createFlash).toHaveBeenCalledTimes(1);
      });
    });

    describe('Edit integration', () => {
      describe('HTTP', () => {
        beforeEach(() => {
          createComponent({
            data: {
              integrations: mockIntegrations,
              currentIntegration: mockIntegrations[0],
              currentHttpIntegration: { id: mockIntegrations[0].id, ...httpMappingData },
            },
            provide: {
              multiIntegrations: true,
            },
            loading: false,
          });
          jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValueOnce({});
          findIntegrationsList().vm.$emit('edit-integration', updateHttpVariables);
        });

        it('requests `currentHttpIntegration`', () => {
          expect(wrapper.vm.$apollo.addSmartQuery).toHaveBeenCalledWith(
            'currentHttpIntegration',
            expect.objectContaining({
              query: getHttpIntegrationQuery,
              result: expect.any(Function),
              update: expect.any(Function),
              variables: expect.any(Function),
            }),
          );
        });

        it('calls `$apollo.mutate` with `updateCurrentHttpIntegrationMutation`', () => {
          expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
            mutation: updateCurrentHttpIntegrationMutation,
            variables: { ...mockIntegrations[0], ...httpMappingData },
          });
        });
      });

      describe('Prometheus', () => {
        it('calls `$apollo.mutate` with `updateCurrentPrometheusIntegrationMutation`', () => {
          createComponent({
            data: {
              integrations: mockIntegrations,
              currentIntegration: mockIntegrations[3],
            },
            loading: false,
          });

          jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue();
          findIntegrationsList().vm.$emit('edit-integration', updatePrometheusVariables);
          expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
            mutation: updateCurrentPrometheusIntegrationMutation,
            variables: mockIntegrations[3],
          });
        });
      });
    });

    describe('Test alert', () => {
      it('makes `updateTestAlert` service call', async () => {
        jest.spyOn(alertsUpdateService, 'updateTestAlert').mockResolvedValueOnce();
        const testPayload = '{"title":"test"}';
        findAlertsSettingsForm().vm.$emit('test-alert-payload', testPayload);
        expect(alertsUpdateService.updateTestAlert).toHaveBeenCalledWith(testPayload);
      });

      it('shows success message on successful test', async () => {
        jest.spyOn(alertsUpdateService, 'updateTestAlert').mockResolvedValueOnce({});
        findAlertsSettingsForm().vm.$emit('test-alert-payload', '');
        await waitForPromises();
        expect(createFlash).toHaveBeenCalledWith({
          message: i18n.alertSent,
          type: FLASH_TYPES.SUCCESS,
        });
      });

      it('shows error message when test alert fails', async () => {
        jest.spyOn(alertsUpdateService, 'updateTestAlert').mockRejectedValueOnce({});
        findAlertsSettingsForm().vm.$emit('test-alert-payload', '');
        await waitForPromises();
        expect(createFlash).toHaveBeenCalledWith({
          message: INTEGRATION_PAYLOAD_TEST_ERROR,
        });
      });
    });
  });

  describe('with mocked Apollo client', () => {
    it('has a selection of integrations loaded via the getIntegrationsQuery', async () => {
      createComponentWithApollo();

      await jest.runOnlyPendingTimers();
      await nextTick();

      expect(findIntegrations()).toHaveLength(4);
    });

    it('calls a mutation with correct parameters and destroys a integration', async () => {
      createComponentWithApollo();

      await destroyHttpIntegration(wrapper);

      expect(destroyIntegrationHandler).toHaveBeenCalled();

      await nextTick();

      expect(findIntegrations()).toHaveLength(3);
    });

    it('displays flash if mutation had a recoverable error', async () => {
      createComponentWithApollo({
        destroyHandler: jest.fn().mockResolvedValue(destroyIntegrationResponseWithErrors),
      });

      await destroyHttpIntegration(wrapper);
      await awaitApolloDomMock();

      expect(createFlash).toHaveBeenCalledWith({ message: 'Houston, we have a problem' });
    });

    it('displays flash if mutation had a non-recoverable error', async () => {
      createComponentWithApollo({
        destroyHandler: jest.fn().mockRejectedValue('Error'),
      });

      await destroyHttpIntegration(wrapper);
      await awaitApolloDomMock();

      expect(createFlash).toHaveBeenCalledWith({
        message: DELETE_INTEGRATION_ERROR,
      });
    });
  });
});
