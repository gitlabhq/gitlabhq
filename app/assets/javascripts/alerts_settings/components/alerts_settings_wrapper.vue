<script>
import { GlButton, GlAlert, GlTabs, GlTab } from '@gitlab/ui';
import createHttpIntegrationMutation from 'ee_else_ce/alerts_settings/graphql/mutations/create_http_integration.mutation.graphql';
import updateHttpIntegrationMutation from 'ee_else_ce/alerts_settings/graphql/mutations/update_http_integration.mutation.graphql';
import createFlash, { FLASH_TYPES } from '~/flash';
import { fetchPolicies } from '~/lib/graphql';
import httpStatusCodes from '~/lib/utils/http_status';
import { typeSet, i18n, tabIndices } from '../constants';
import createPrometheusIntegrationMutation from '../graphql/mutations/create_prometheus_integration.mutation.graphql';
import destroyHttpIntegrationMutation from '../graphql/mutations/destroy_http_integration.mutation.graphql';
import resetHttpTokenMutation from '../graphql/mutations/reset_http_token.mutation.graphql';
import resetPrometheusTokenMutation from '../graphql/mutations/reset_prometheus_token.mutation.graphql';
import updateCurrentHttpIntegrationMutation from '../graphql/mutations/update_current_http_integration.mutation.graphql';
import updateCurrentPrometheusIntegrationMutation from '../graphql/mutations/update_current_prometheus_integration.mutation.graphql';
import updatePrometheusIntegrationMutation from '../graphql/mutations/update_prometheus_integration.mutation.graphql';
import getCurrentIntegrationQuery from '../graphql/queries/get_current_integration.query.graphql';
import getHttpIntegrationQuery from '../graphql/queries/get_http_integration.query.graphql';
import getIntegrationsQuery from '../graphql/queries/get_integrations.query.graphql';
import service from '../services';
import {
  updateStoreAfterIntegrationDelete,
  updateStoreAfterIntegrationAdd,
} from '../utils/cache_updates';
import {
  DELETE_INTEGRATION_ERROR,
  ADD_INTEGRATION_ERROR,
  RESET_INTEGRATION_TOKEN_ERROR,
  UPDATE_INTEGRATION_ERROR,
  INTEGRATION_PAYLOAD_TEST_ERROR,
  INTEGRATION_INACTIVE_PAYLOAD_TEST_ERROR,
  DEFAULT_ERROR,
} from '../utils/error_messages';
import AlertsForm from './alerts_form.vue';
import IntegrationsList from './alerts_integrations_list.vue';
import AlertSettingsForm from './alerts_settings_form.vue';

export default {
  typeSet,
  i18n,
  components: {
    IntegrationsList,
    AlertsForm,
    AlertSettingsForm,
    GlAlert,
    GlButton,
    GlTabs,
    GlTab,
  },
  inject: {
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
        const { alertManagementIntegrations: { nodes = [] } = {} } = data.project || {};
        return nodes;
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
      integrations: [],
      currentIntegration: null,
      currentHttpIntegration: null,
      newIntegration: null,
      formVisible: false,
      showSuccessfulCreateAlert: false,
      tabIndex: tabIndices.configureDetails,
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.integrations.loading;
    },
    canAddIntegration() {
      return this.multiIntegrations || this.integrations.length < 2;
    },
  },
  methods: {
    isHttp(type) {
      return type === typeSet.http;
    },
    createNewIntegration({ type, variables }, testAfterSubmit) {
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
          },
        })
        .then(({ data: { httpIntegrationCreate, prometheusIntegrationCreate } = {} } = {}) => {
          const error = httpIntegrationCreate?.errors[0] || prometheusIntegrationCreate?.errors[0];
          if (error) {
            createFlash({ message: error });
            return;
          }

          const { integration } = httpIntegrationCreate || prometheusIntegrationCreate;
          this.newIntegration = integration;
          this.showSuccessfulCreateAlert = true;

          if (testAfterSubmit) {
            this.viewIntegration(this.newIntegration, tabIndices.sendTestAlert);
          } else {
            this.setFormVisibility(false);
          }
        })
        .catch(() => {
          createFlash({ message: ADD_INTEGRATION_ERROR });
        })
        .finally(() => {
          this.isUpdating = false;
        });
    },
    updateIntegration({ type, variables }, testAfterSubmit) {
      this.isUpdating = true;
      return this.$apollo
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
            createFlash({ message: error });
            return;
          }

          const integration =
            httpIntegrationUpdate?.integration || prometheusIntegrationUpdate?.integration;

          if (testAfterSubmit) {
            this.viewIntegration(integration, tabIndices.sendTestAlert);
          } else {
            this.clearCurrentIntegration({ type });
          }

          createFlash({
            message: this.$options.i18n.changesSaved,
            type: FLASH_TYPES.SUCCESS,
          });
        })
        .catch(() => {
          createFlash({ message: UPDATE_INTEGRATION_ERROR });
        })
        .finally(() => {
          this.isUpdating = false;
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
      const currentIntegration = this.integrations.find((integration) => integration.id === id);

      if (this.multiIntegrations && this.isHttp(type)) {
        this.$apollo.addSmartQuery('currentHttpIntegration', {
          query: getHttpIntegrationQuery,
          variables() {
            return {
              projectPath: this.projectPath,
              id,
            };
          },
          update(data) {
            const {
              project: {
                alertManagementHttpIntegrations: { nodes = [{}] },
              },
            } = data;
            return nodes[0];
          },
          result() {
            this.viewIntegration(
              { ...currentIntegration, ...this.currentHttpIntegration },
              tabIndices.viewCredentials,
            );
          },
          error() {
            createFlash({ message: DEFAULT_ERROR });
          },
        });
      } else {
        this.viewIntegration(currentIntegration, tabIndices.viewCredentials);
      }
    },
    viewIntegration(integration, tabIndex) {
      this.$apollo
        .mutate({
          mutation: this.isHttp(integration.type)
            ? updateCurrentHttpIntegrationMutation
            : updateCurrentPrometheusIntegrationMutation,
          variables: integration,
        })
        .then(() => {
          this.setFormVisibility(true);
          this.tabIndex = tabIndex;
        })
        .catch(() => {
          createFlash({ message: DEFAULT_ERROR });
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
      if (type) {
        this.$apollo.mutate({
          mutation: this.isHttp(type)
            ? updateCurrentHttpIntegrationMutation
            : updateCurrentPrometheusIntegrationMutation,
          variables: {},
        });
      }
      this.setFormVisibility(false);
    },
    testAlertPayload(payload) {
      return service
        .updateTestAlert(payload)
        .then(() => {
          return createFlash({
            message: this.$options.i18n.alertSent,
            type: FLASH_TYPES.SUCCESS,
          });
        })
        .catch((error) => {
          let message = INTEGRATION_PAYLOAD_TEST_ERROR;
          if (error.response?.status === httpStatusCodes.FORBIDDEN) {
            message = INTEGRATION_INACTIVE_PAYLOAD_TEST_ERROR;
          }
          createFlash({ message });
        });
    },
    saveAndTestAlertPayload(integration, payload) {
      return this.updateIntegration(integration, false).then(() => {
        this.testAlertPayload(payload);
      });
    },
    setFormVisibility(visible) {
      this.formVisible = visible;
    },
    viewCreatedIntegration() {
      this.viewIntegration(this.newIntegration, tabIndices.viewCredentials);
      this.showSuccessfulCreateAlert = false;
      this.newIntegration = null;
    },
  },
};
</script>

<template>
  <gl-tabs data-testid="alert-integration-settings">
    <gl-tab :title="$options.i18n.settingsTabs.currentIntegrations">
      <gl-alert
        v-if="showSuccessfulCreateAlert"
        class="gl-mt-n2"
        :primary-button-text="$options.i18n.integrationCreated.btnCaption"
        :title="$options.i18n.integrationCreated.title"
        @primaryAction="viewCreatedIntegration"
        @dismiss="showSuccessfulCreateAlert = false"
      >
        {{ $options.i18n.integrationCreated.successMsg }}
      </gl-alert>

      <integrations-list
        :integrations="integrations"
        :loading="loading"
        @edit-integration="editIntegration"
        @delete-integration="deleteIntegration"
      />
      <gl-button
        v-if="canAddIntegration && !formVisible"
        category="secondary"
        variant="confirm"
        data-testid="add-integration-btn"
        class="gl-mt-3"
        @click="setFormVisibility(true)"
      >
        {{ $options.i18n.addNewIntegration }}
      </gl-button>
      <alert-settings-form
        v-if="formVisible"
        :loading="isUpdating"
        :can-add-integration="canAddIntegration"
        :alert-fields="alertFields"
        :tab-index="tabIndex"
        @create-new-integration="createNewIntegration"
        @update-integration="updateIntegration"
        @reset-token="resetToken"
        @clear-current-integration="clearCurrentIntegration"
        @test-alert-payload="testAlertPayload"
        @save-and-test-alert-payload="saveAndTestAlertPayload"
      />
    </gl-tab>
    <gl-tab :title="$options.i18n.settingsTabs.integrationSettings">
      <alerts-form class="gl-pt-3" data-testid="alert-integration-settings-tab" />
    </gl-tab>
  </gl-tabs>
</template>
