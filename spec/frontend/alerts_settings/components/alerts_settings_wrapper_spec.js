import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createHttpIntegrationMutation from 'ee_else_ce/alerts_settings/graphql/mutations/create_http_integration.mutation.graphql';
import updateHttpIntegrationMutation from 'ee_else_ce/alerts_settings/graphql/mutations/update_http_integration.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
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
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_FORBIDDEN, HTTP_STATUS_UNPROCESSABLE_ENTITY } from '~/lib/utils/http_status';
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
  prometheusIntegrationsList,
} from './mocks/apollo_mock';
import mockIntegrations from './mocks/integrations.json';

jest.mock('~/alert');

describe('AlertsSettingsWrapper', () => {
  let wrapper;
  let fakeApollo;
  let destroyIntegrationHandler;

  const findIntegrationsList = () => wrapper.findComponent(IntegrationsList);
  const findLoader = () => findIntegrationsList().findComponent(GlLoadingIcon);
  const findIntegrations = () => findIntegrationsList().findAll('table tbody tr');
  const findAddIntegrationBtn = () => wrapper.findByTestId('crud-form-toggle');
  const findAlertsSettingsForm = () => wrapper.findComponent(AlertsSettingsForm);
  const findAlert = () => wrapper.findComponent(GlAlert);

  function destroyHttpIntegration(localWrapper) {
    localWrapper
      .findComponent(IntegrationsList)
      .vm.$emit('delete-integration', { id: integrationToDestroy.id });
  }

  const integrationResponse = ({
    mutation,
    id = getIntegrationsQueryResponse.data.project.id,
    extraAttributes = {},
  }) => ({
    data: { [mutation]: { integration: { id }, ...extraAttributes } },
  });

  const createIntegrationResponse = integrationResponse({
    mutation: 'httpIntegrationCreate',
    extraAttributes: {
      errors: [],
    },
  });

  const updateIntegrationResponse = integrationResponse({
    mutation: 'updateHttpIntegrationMutation',
  });

  const resetHttpTokenResponse = integrationResponse({
    mutation: 'resetHttpTokenMutation',
  });

  const createPrometheousIntegrationResponse = integrationResponse({
    mutation: 'createPrometheusIntegrationMutation',
    id: '2',
  });

  const resetPrometheousResponse = integrationResponse({
    mutation: 'resetPrometheusTokenMutation',
  });

  const currentHttpIntegrationResponse = {
    data: {
      project: {
        id: '1',
        alertManagementHttpIntegrations: {
          nodes: [
            {
              __typename: 'AlertManagementIntegration',
              id: 'gid://gitlab/AlertManagement::HttpIntegration/7',
              type: 'HTTP',
              active: true,
              name: 'test',
              url: 'http://192.168.1.152:3000/root/autodevops/alerts/notify/test/eddd36969b2d3d6a.json',
              token: '7eb24af194116411ec8d66b58c6b0d2e',
            },
          ],
        },
      },
    },
  };

  const currentIntegration =
    getIntegrationsQueryResponse.data.project.alertManagementIntegrations.nodes[0];

  const createIntegrationHandler = jest.fn().mockResolvedValue(createIntegrationResponse);

  const updateIntegrationHandler = jest.fn().mockResolvedValue(updateIntegrationResponse);

  const resetTokenHandler = jest.fn().mockResolvedValue(resetHttpTokenResponse);

  const createPrometheousIntegrationHandler = jest
    .fn()
    .mockResolvedValue(createPrometheousIntegrationResponse);

  const updatePrometheousIntegrationHandler = jest
    .fn()
    .mockResolvedValue(createPrometheousIntegrationResponse);

  const resetPrometheousIntegrationHandler = jest.fn().mockResolvedValue(resetPrometheousResponse);

  const currentHttpIntegrationQueryHandler = jest
    .fn()
    .mockResolvedValue(currentHttpIntegrationResponse);

  const mockUpdateCurrentHttpIntegrationMutationHandler = jest.fn();

  function createComponentWithApollo({
    destroyHandler = jest.fn().mockResolvedValue(destroyIntegrationResponse),
    provide = {},
    currentIntegrationQueryHandler = jest.fn().mockResolvedValue(currentIntegration),
    getIntegrationQueryHandler = jest.fn().mockResolvedValue(getIntegrationsQueryResponse),
    createIntegrationResponseHandler = createIntegrationHandler,
    updateIntegrationResponseHandler = updateIntegrationHandler,
    resetTokenResponseHandler = resetTokenHandler,
    createPrometheousResponseHandler = createPrometheousIntegrationHandler,
    updatePrometheousResponseIntegrationHandler = updatePrometheousIntegrationHandler,
    resetPrometheousResponseIntegrationHandler = resetPrometheousIntegrationHandler,
    currentHttpIntegrationQueryResponseHandler = currentHttpIntegrationQueryHandler,
  } = {}) {
    Vue.use(VueApollo);
    destroyIntegrationHandler = destroyHandler;

    const requestHandlers = [
      [getIntegrationsQuery, getIntegrationQueryHandler],
      [destroyHttpIntegrationMutation, destroyIntegrationHandler],
      [createHttpIntegrationMutation, createIntegrationResponseHandler],
      [updateHttpIntegrationMutation, updateIntegrationResponseHandler],
      [resetHttpTokenMutation, resetTokenResponseHandler],
      [createPrometheusIntegrationMutation, createPrometheousResponseHandler],
      [updatePrometheusIntegrationMutation, updatePrometheousResponseIntegrationHandler],
      [resetPrometheusTokenMutation, resetPrometheousResponseIntegrationHandler],
      [getHttpIntegrationQuery, currentHttpIntegrationQueryResponseHandler],
    ];

    fakeApollo = createMockApollo(requestHandlers, {
      Query: {
        currentIntegration: currentIntegrationQueryHandler,
      },
      Mutation: {
        updateCurrentIntegration: mockUpdateCurrentHttpIntegrationMutationHandler,
      },
    });

    wrapper = extendedWrapper(
      mount(AlertsSettingsWrapper, {
        apolloProvider: fakeApollo,
        provide: {
          ...provide,
          alertSettings: {
            templates: [],
          },
          service: {},
        },
        stubs: {
          AlertSettingsForm: true,
        },
      }),
    );
  }

  describe('template', () => {
    beforeEach(() => {
      createComponentWithApollo();
    });

    it('renders alerts integrations list', async () => {
      expect(findLoader().exists()).toBe(true);

      await waitForPromises();
      expect(findIntegrations()).toHaveLength(mockIntegrations.length);
    });

    it('renders `Add new integration` button when multiple integrations are supported', async () => {
      createComponentWithApollo({
        provide: {
          multiIntegrations: true,
        },
      });

      await waitForPromises();

      expect(findAddIntegrationBtn().exists()).toBe(true);
    });

    it('does NOT render settings form by default', () => {
      expect(findAlertsSettingsForm().exists()).toBe(false);
    });

    it('hides `add new integration` button and displays setting form on btn click', async () => {
      createComponentWithApollo({
        provide: {
          multiIntegrations: true,
        },
      });

      await waitForPromises();

      const addNewIntegrationBtn = findAddIntegrationBtn();
      expect(addNewIntegrationBtn.exists()).toBe(true);
      await addNewIntegrationBtn.vm.$emit('click');
      expect(findAlertsSettingsForm().exists()).toBe(true);
      expect(addNewIntegrationBtn.exists()).toBe(false);
    });

    it('shows loading indicator inside the IntegrationsList table', () => {
      createComponentWithApollo();

      expect(findIntegrationsList().exists()).toBe(true);
      expect(findLoader().exists()).toBe(true);
    });
  });

  describe('Integration updates', () => {
    beforeEach(async () => {
      createComponentWithApollo({
        provide: {
          multiIntegrations: true,
        },
      });

      await waitForPromises();

      await findAddIntegrationBtn().vm.$emit('click');
    });

    describe('Create', () => {
      beforeEach(() => {
        findAlertsSettingsForm().vm.$emit('create-new-integration', {
          type: typeSet.http,
          variables: createHttpVariables,
        });
      });

      it('`createIntegrationHandler` is called when a new integration is created', async () => {
        expect(createIntegrationHandler).toHaveBeenCalledTimes(1);
        expect(createIntegrationHandler).toHaveBeenCalledWith({
          ...createHttpVariables,
        });

        await waitForPromises();

        expect(findAlert().exists()).toBe(true);
      });
    });

    it('`updateHttpIntegrationHandler` is called when updated', () => {
      findAlertsSettingsForm().vm.$emit('update-integration', {
        type: typeSet.http,
        variables: updateHttpVariables,
      });

      expect(updateIntegrationHandler).toHaveBeenCalledTimes(1);
      expect(updateIntegrationHandler).toHaveBeenCalledWith({
        ...updateHttpVariables,
        id: currentIntegration.id,
      });
    });

    it('`resetHttpTokenMutationHandler` is called on reset-token', () => {
      findAlertsSettingsForm().vm.$emit('reset-token', {
        type: typeSet.http,
        variables: { id: HTTP_ID },
      });

      expect(resetTokenHandler).toHaveBeenCalledWith({
        id: HTTP_ID,
      });
    });

    it('`createPrometheusIntegrationMutation` is called on creating a prometheus integration', () => {
      findAlertsSettingsForm().vm.$emit('create-new-integration', {
        type: typeSet.prometheus,
        variables: createPrometheusVariables,
      });

      expect(createPrometheousIntegrationHandler).toHaveBeenCalledTimes(1);
      expect(createPrometheousIntegrationHandler).toHaveBeenCalledWith({
        ...createPrometheusVariables,
      });
    });

    it('`updatePrometheusIntegrationMutation` is called on prometheus mutation update', () => {
      findAlertsSettingsForm().vm.$emit('update-integration', {
        type: typeSet.prometheus,
        variables: updatePrometheusVariables,
      });

      expect(updatePrometheousIntegrationHandler).toHaveBeenCalledTimes(1);

      expect(updatePrometheousIntegrationHandler).toHaveBeenCalledWith({
        ...updatePrometheusVariables,
        id: currentIntegration.id,
      });
    });

    it('`resetPrometheusTokenMutation` is called on prometheus reset token', () => {
      findAlertsSettingsForm().vm.$emit('reset-token', {
        type: typeSet.prometheus,
        variables: { id: PROMETHEUS_ID },
      });

      expect(resetPrometheousIntegrationHandler).toHaveBeenCalledWith({
        id: PROMETHEUS_ID,
      });
    });

    it('shows an error alert when integration creation fails', async () => {
      createComponentWithApollo({
        createIntegrationResponseHandler: jest.fn().mockRejectedValue(ADD_INTEGRATION_ERROR),
        provide: {
          multiIntegrations: true,
        },
      });

      await waitForPromises();

      await findAddIntegrationBtn().vm.$emit('click');

      await nextTick();
      findAlertsSettingsForm().vm.$emit('create-new-integration', {});

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message: ADD_INTEGRATION_ERROR });
    });

    it('shows an error alert when integration token reset fails', async () => {
      createComponentWithApollo({
        resetTokenResponseHandler: jest.fn().mockRejectedValue(ADD_INTEGRATION_ERROR),
        provide: {
          multiIntegrations: true,
        },
      });

      await waitForPromises();

      await findAddIntegrationBtn().vm.$emit('click');

      await nextTick();

      findAlertsSettingsForm().vm.$emit('reset-token', {});

      await waitForPromises();
      expect(createAlert).toHaveBeenCalledWith({ message: RESET_INTEGRATION_TOKEN_ERROR });
    });

    it('shows an error alert when integration update fails', async () => {
      createComponentWithApollo({
        updateIntegrationResponseHandler: jest.fn().mockRejectedValue(errorMsg),
        provide: {
          multiIntegrations: true,
        },
      });

      await waitForPromises();

      await findAddIntegrationBtn().vm.$emit('click');

      await nextTick();

      findAlertsSettingsForm().vm.$emit('update-integration', {});

      await waitForPromises();
      expect(createAlert).toHaveBeenCalledWith({ message: UPDATE_INTEGRATION_ERROR });
    });

    describe('Test alert failure', () => {
      let mock;
      beforeEach(() => {
        mock = new AxiosMockAdapter(axios);
      });
      afterEach(() => {
        mock.restore();
      });

      it('shows an error alert when integration test payload is invalid', async () => {
        mock.onPost(/(.*)/).replyOnce(HTTP_STATUS_UNPROCESSABLE_ENTITY);
        await wrapper.vm.testAlertPayload({ endpoint: '', data: '', token: '' });
        expect(createAlert).toHaveBeenCalledWith({ message: INTEGRATION_PAYLOAD_TEST_ERROR });
        expect(createAlert).toHaveBeenCalledTimes(1);
      });

      it('shows an error alert when integration is not activated', async () => {
        mock.onPost(/(.*)/).replyOnce(HTTP_STATUS_FORBIDDEN);
        await wrapper.vm.testAlertPayload({ endpoint: '', data: '', token: '' });
        expect(createAlert).toHaveBeenCalledWith({
          message: INTEGRATION_INACTIVE_PAYLOAD_TEST_ERROR,
        });
        expect(createAlert).toHaveBeenCalledTimes(1);
      });
    });

    describe('Edit integration', () => {
      describe('HTTP', () => {
        beforeEach(async () => {
          createComponentWithApollo({
            provide: {
              multiIntegrations: true,
            },
          });

          await waitForPromises();

          findIntegrationsList().vm.$emit('edit-integration', updateHttpVariables);

          await nextTick();
        });

        it('calls `currentHttpIntegration` on editing', () => {
          expect(currentHttpIntegrationQueryHandler).toHaveBeenCalled();
        });

        it('`updateCurrentHttpIntegrationMutation` is called when we after editing', async () => {
          await waitForPromises();

          expect(mockUpdateCurrentHttpIntegrationMutationHandler).toHaveBeenCalledTimes(1);
        });
      });

      describe('Prometheus', () => {
        it('`updateCurrentPrometheusIntegrationMutation` is called on editing', async () => {
          const currentMockIntegration =
            prometheusIntegrationsList.data.project.alertManagementIntegrations.nodes[3];
          createComponentWithApollo({
            provide: {
              multiIntegrations: true,
            },
            getIntegrationQueryHandler: jest.fn().mockResolvedValue(prometheusIntegrationsList),
            currentIntegrationQueryHandler: jest.fn().mockResolvedValue(currentMockIntegration),
            currentHttpIntegrationQueryResponseHandler: jest
              .fn()
              .mockResolvedValue(currentHttpIntegrationResponse),
          });

          await waitForPromises();

          findIntegrationsList().vm.$emit('edit-integration', {
            ...updatePrometheusVariables,
          });

          await nextTick();

          expect(mockUpdateCurrentHttpIntegrationMutationHandler).toHaveBeenCalledTimes(1);
          expect(mockUpdateCurrentHttpIntegrationMutationHandler).toHaveBeenCalledWith(
            {},
            // Using expect.objectContaining , because of limitations
            // Check https://gitlab.com/gitlab-org/gitlab/-/issues/420993
            expect.objectContaining({ id: mockIntegrations[3].id }),
            expect.anything(),
            expect.anything(),
          );
        });
      });
    });

    describe('Test alert', () => {
      it('makes `updateTestAlert` service call', () => {
        jest.spyOn(alertsUpdateService, 'updateTestAlert').mockResolvedValueOnce();
        const testPayload = '{"title":"test"}';
        findAlertsSettingsForm().vm.$emit('test-alert-payload', testPayload);
        expect(alertsUpdateService.updateTestAlert).toHaveBeenCalledWith(testPayload);
      });

      it('shows success message on successful test', async () => {
        jest.spyOn(alertsUpdateService, 'updateTestAlert').mockResolvedValueOnce({});
        findAlertsSettingsForm().vm.$emit('test-alert-payload', '');
        await waitForPromises();
        expect(createAlert).toHaveBeenCalledWith({
          message: i18n.alertSent,
          variant: VARIANT_SUCCESS,
        });
      });

      it('shows error message when test alert fails', async () => {
        jest.spyOn(alertsUpdateService, 'updateTestAlert').mockRejectedValueOnce({});
        findAlertsSettingsForm().vm.$emit('test-alert-payload', '');
        await waitForPromises();
        expect(createAlert).toHaveBeenCalledWith({
          message: INTEGRATION_PAYLOAD_TEST_ERROR,
        });
      });
    });
  });

  describe('with mocked Apollo client', () => {
    it('has a selection of integrations loaded via the getIntegrationsQuery', async () => {
      createComponentWithApollo();
      await waitForPromises();

      expect(findIntegrations()).toHaveLength(4);
    });

    it('calls a mutation with correct parameters and destroys a integration', async () => {
      createComponentWithApollo();
      await waitForPromises();

      destroyHttpIntegration(wrapper);

      expect(destroyIntegrationHandler).toHaveBeenCalled();
    });

    it('displays alert if mutation had a recoverable error', async () => {
      createComponentWithApollo({
        destroyHandler: jest.fn().mockResolvedValue(destroyIntegrationResponseWithErrors),
      });

      await destroyHttpIntegration(wrapper);
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message: 'Houston, we have a problem' });
    });

    it('displays alert if mutation had a non-recoverable error', async () => {
      createComponentWithApollo({
        destroyHandler: jest.fn().mockRejectedValue('Error'),
      });

      await destroyHttpIntegration(wrapper);
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: DELETE_INTEGRATION_ERROR,
      });
    });
  });
});
