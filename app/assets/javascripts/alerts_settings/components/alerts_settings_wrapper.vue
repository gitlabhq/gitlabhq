<script>
import createFlash, { FLASH_TYPES } from '~/flash';
import { fetchPolicies } from '~/lib/graphql';
import { s__ } from '~/locale';
import { typeSet } from '../constants';
import createHttpIntegrationMutation from '../graphql/mutations/create_http_integration.mutation.graphql';
import createPrometheusIntegrationMutation from '../graphql/mutations/create_prometheus_integration.mutation.graphql';
import destroyHttpIntegrationMutation from '../graphql/mutations/destroy_http_integration.mutation.graphql';
import resetHttpTokenMutation from '../graphql/mutations/reset_http_token.mutation.graphql';
import resetPrometheusTokenMutation from '../graphql/mutations/reset_prometheus_token.mutation.graphql';
import updateCurrentHttpIntegrationMutation from '../graphql/mutations/update_current_http_integration.mutation.graphql';
import updateCurrentPrometheusIntegrationMutation from '../graphql/mutations/update_current_prometheus_integration.mutation.graphql';
import updateHttpIntegrationMutation from '../graphql/mutations/update_http_integration.mutation.graphql';
import updatePrometheusIntegrationMutation from '../graphql/mutations/update_prometheus_integration.mutation.graphql';
import getCurrentIntegrationQuery from '../graphql/queries/get_current_integration.query.graphql';
import getHttpIntegrationsQuery from '../graphql/queries/get_http_integrations.query.graphql';
import getIntegrationsQuery from '../graphql/queries/get_integrations.query.graphql';
import service from '../services';
import {
  updateStoreAfterIntegrationDelete,
  updateStoreAfterIntegrationAdd,
  updateStoreAfterHttpIntegrationAdd,
} from '../utils/cache_updates';
import {
  DELETE_INTEGRATION_ERROR,
  ADD_INTEGRATION_ERROR,
  RESET_INTEGRATION_TOKEN_ERROR,
  UPDATE_INTEGRATION_ERROR,
  INTEGRATION_PAYLOAD_TEST_ERROR,
} from '../utils/error_messages';
import IntegrationsList from './alerts_integrations_list.vue';
import AlertSettingsForm from './alerts_settings_form.vue';

export default {
  typeSet,
  i18n: {
    changesSaved: s__(
      'AlertsIntegrations|The integration has been successfully saved. Alerts from this new integration should now appear on your alerts list.',
    ),
    integrationRemoved: s__('AlertsIntegrations|The integration has been successfully removed.'),
    alertSent: s__(
      'AlertsIntegrations|The test alert has been successfully sent, and should now be visible on your alerts list.',
    ),
  },
  components: {
    IntegrationsList,
    AlertSettingsForm,
  },
  inject: {
    generic: {
      default: {},
    },
    prometheus: {
      default: {},
    },
    projectPath: {
      default: '',
    },
    multiIntegrations: {
      default: false,
    },
  },
  props: {
    alertFields: {
      type: Array,
      required: false,
      default: null,
    },
  },
  apollo: {
    integrations: {
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      query: getIntegrationsQuery,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update(data) {
        const { alertManagementIntegrations: { nodes: list = [] } = {} } = data.project || {};

        return {
          list,
        };
      },
      error(err) {
        createFlash({ message: err });
      },
    },
    // TODO: we'll need to update the logic to request specific http integration by its id on edit
    // when BE adds support for it https://gitlab.com/gitlab-org/gitlab/-/issues/321674
    // currently the request for ALL http integrations is made and on specific integration edit we search it in the list
    httpIntegrations: {
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      query: getHttpIntegrationsQuery,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update(data) {
        const { alertManagementHttpIntegrations: { nodes: list = [] } = {} } = data.project || {};

        return {
          list,
        };
      },
      error(err) {
        createFlash({ message: err });
      },
    },
    currentIntegration: {
      query: getCurrentIntegrationQuery,
    },
  },
  data() {
    return {
      isUpdating: false,
      testAlertPayload: null,
      integrations: {},
      httpIntegrations: {},
      currentIntegration: null,
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.integrations.loading;
    },
    canAddIntegration() {
      return this.multiIntegrations || this.integrations?.list?.length < 2;
    },
  },
  methods: {
    isHttp(type) {
      return type === typeSet.http;
    },
    createNewIntegration({ type, variables }) {
      const { projectPath } = this;

      const isHttp = this.isHttp(type);
      this.isUpdating = true;
      this.$apollo
        .mutate({
          mutation: isHttp ? createHttpIntegrationMutation : createPrometheusIntegrationMutation,
          variables: {
            ...variables,
            projectPath,
          },
          update(store, { data }) {
            updateStoreAfterIntegrationAdd(store, getIntegrationsQuery, data, { projectPath });
            if (isHttp) {
              updateStoreAfterHttpIntegrationAdd(store, getHttpIntegrationsQuery, data, {
                projectPath,
              });
            }
          },
        })
        .then(({ data: { httpIntegrationCreate, prometheusIntegrationCreate } = {} } = {}) => {
          const error = httpIntegrationCreate?.errors[0] || prometheusIntegrationCreate?.errors[0];
          if (error) {
            return createFlash({ message: error });
          }

          if (this.testAlertPayload) {
            const integration =
              httpIntegrationCreate?.integration || prometheusIntegrationCreate?.integration;

            const payload = {
              ...this.testAlertPayload,
              endpoint: integration.url,
              token: integration.token,
            };
            return this.validateAlertPayload(payload);
          }

          return createFlash({
            message: this.$options.i18n.changesSaved,
            type: FLASH_TYPES.SUCCESS,
          });
        })
        .catch(() => {
          createFlash({ message: ADD_INTEGRATION_ERROR });
        })
        .finally(() => {
          this.isUpdating = false;
        });
    },
    updateIntegration({ type, variables }) {
      this.isUpdating = true;
      this.$apollo
        .mutate({
          mutation: this.isHttp(type)
            ? updateHttpIntegrationMutation
            : updatePrometheusIntegrationMutation,
          variables: {
            ...variables,
            id: this.currentIntegration.id,
          },
        })
        .then(({ data: { httpIntegrationUpdate, prometheusIntegrationUpdate } = {} } = {}) => {
          const error = httpIntegrationUpdate?.errors[0] || prometheusIntegrationUpdate?.errors[0];
          if (error) {
            return createFlash({ message: error });
          }

          if (this.testAlertPayload) {
            return this.validateAlertPayload();
          }

          this.clearCurrentIntegration({ type });

          return createFlash({
            message: this.$options.i18n.changesSaved,
            type: FLASH_TYPES.SUCCESS,
          });
        })
        .catch(() => {
          createFlash({ message: UPDATE_INTEGRATION_ERROR });
        })
        .finally(() => {
          this.isUpdating = false;
          this.testAlertPayload = null;
        });
    },
    resetToken({ type, variables }) {
      this.isUpdating = true;
      this.$apollo
        .mutate({
          mutation: this.isHttp(type) ? resetHttpTokenMutation : resetPrometheusTokenMutation,
          variables,
        })
        .then(
          ({ data: { httpIntegrationResetToken, prometheusIntegrationResetToken } = {} } = {}) => {
            const [error] =
              httpIntegrationResetToken?.errors || prometheusIntegrationResetToken?.errors;
            if (error) {
              return createFlash({ message: error });
            }

            const integration =
              httpIntegrationResetToken?.integration ||
              prometheusIntegrationResetToken?.integration;

            this.$apollo.mutate({
              mutation: this.isHttp(type)
                ? updateCurrentHttpIntegrationMutation
                : updateCurrentPrometheusIntegrationMutation,
              variables: integration,
            });

            return createFlash({
              message: this.$options.i18n.changesSaved,
              type: FLASH_TYPES.SUCCESS,
            });
          },
        )
        .catch(() => {
          createFlash({ message: RESET_INTEGRATION_TOKEN_ERROR });
        })
        .finally(() => {
          this.isUpdating = false;
        });
    },
    editIntegration({ id, type }) {
      let currentIntegration = this.integrations.list.find((integration) => integration.id === id);
      if (this.isHttp(type)) {
        const httpIntegrationMappingData = this.httpIntegrations.list.find(
          (integration) => integration.id === id,
        );
        currentIntegration = { ...currentIntegration, ...httpIntegrationMappingData };
      }

      this.$apollo.mutate({
        mutation: this.isHttp(type)
          ? updateCurrentHttpIntegrationMutation
          : updateCurrentPrometheusIntegrationMutation,
        variables: currentIntegration,
      });
    },
    deleteIntegration({ id, type }) {
      const { projectPath } = this;

      this.isUpdating = true;
      this.$apollo
        .mutate({
          mutation: destroyHttpIntegrationMutation,
          variables: { id },
          update(store, { data }) {
            updateStoreAfterIntegrationDelete(store, getIntegrationsQuery, data, { projectPath });
          },
        })
        .then(({ data: { httpIntegrationDestroy } = {} } = {}) => {
          const error = httpIntegrationDestroy?.errors[0];
          if (error) {
            return createFlash({ message: error });
          }
          this.clearCurrentIntegration({ type });
          return createFlash({
            message: this.$options.i18n.integrationRemoved,
            type: FLASH_TYPES.SUCCESS,
          });
        })
        .catch(() => {
          createFlash({ message: DELETE_INTEGRATION_ERROR });
        })
        .finally(() => {
          this.isUpdating = false;
        });
    },
    clearCurrentIntegration({ type }) {
      this.$apollo.mutate({
        mutation: this.isHttp(type)
          ? updateCurrentHttpIntegrationMutation
          : updateCurrentPrometheusIntegrationMutation,
        variables: {},
      });
    },
    setTestAlertPayload(payload) {
      this.testAlertPayload = payload;
    },
    validateAlertPayload(payload) {
      return service
        .updateTestAlert(payload ?? this.testAlertPayload)
        .then(() => {
          return createFlash({
            message: this.$options.i18n.alertSent,
            type: FLASH_TYPES.SUCCESS,
          });
        })
        .catch(() => {
          createFlash({ message: INTEGRATION_PAYLOAD_TEST_ERROR });
        });
    },
  },
};
</script>

<template>
  <div>
    <integrations-list
      :integrations="integrations.list"
      :loading="loading"
      @edit-integration="editIntegration"
      @delete-integration="deleteIntegration"
    />
    <alert-settings-form
      :loading="isUpdating"
      :can-add-integration="canAddIntegration"
      :alert-fields="alertFields"
      @create-new-integration="createNewIntegration"
      @update-integration="updateIntegration"
      @reset-token="resetToken"
      @clear-current-integration="clearCurrentIntegration"
      @set-test-alert-payload="setTestAlertPayload"
    />
  </div>
</template>
