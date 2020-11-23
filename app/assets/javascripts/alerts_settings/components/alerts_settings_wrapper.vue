<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { fetchPolicies } from '~/lib/graphql';
import createFlash, { FLASH_TYPES } from '~/flash';
import getIntegrationsQuery from '../graphql/queries/get_integrations.query.graphql';
import getCurrentIntegrationQuery from '../graphql/queries/get_current_integration.query.graphql';
import createHttpIntegrationMutation from '../graphql/mutations/create_http_integration.mutation.graphql';
import createPrometheusIntegrationMutation from '../graphql/mutations/create_prometheus_integration.mutation.graphql';
import updateHttpIntegrationMutation from '../graphql/mutations/update_http_integration.mutation.graphql';
import updatePrometheusIntegrationMutation from '../graphql/mutations/update_prometheus_integration.mutation.graphql';
import destroyHttpIntegrationMutation from '../graphql/mutations/destroy_http_integration.mutation.graphql';
import resetHttpTokenMutation from '../graphql/mutations/reset_http_token.mutation.graphql';
import resetPrometheusTokenMutation from '../graphql/mutations/reset_prometheus_token.mutation.graphql';
import updateCurrentIntergrationMutation from '../graphql/mutations/update_current_intergration.mutation.graphql';
import IntegrationsList from './alerts_integrations_list.vue';
import AlertSettingsForm from './alerts_settings_form.vue';
import service from '../services';
import { typeSet } from '../constants';
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
} from '../utils/error_messages';

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
    // TODO: Will be removed in 13.7 as part of: https://gitlab.com/gitlab-org/gitlab/-/issues/273657
    GlAlert,
    GlLink,
    GlSprintf,
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
    // TODO: Will be removed in 13.7 as part of: https://gitlab.com/gitlab-org/gitlab/-/issues/273657
    opsgenie: {
      default: {},
    },
    projectPath: {
      default: '',
    },
    multiIntegrations: {
      default: false,
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
    currentIntegration: {
      query: getCurrentIntegrationQuery,
    },
  },
  data() {
    return {
      isUpdating: false,
      testAlertPayload: null,
      integrations: {},
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
    canManageOpsgenie() {
      return (
        this.integrations?.list?.every(({ active }) => active === false) ||
        this.integrations?.list?.length === 0
      );
    },
  },
  methods: {
    createNewIntegration({ type, variables }) {
      const { projectPath } = this;

      this.isUpdating = true;
      this.$apollo
        .mutate({
          mutation:
            type === this.$options.typeSet.http
              ? createHttpIntegrationMutation
              : createPrometheusIntegrationMutation,
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
          mutation:
            type === this.$options.typeSet.http
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

          this.clearCurrentIntegration();

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
          mutation:
            type === this.$options.typeSet.http
              ? resetHttpTokenMutation
              : resetPrometheusTokenMutation,
          variables,
        })
        .then(
          ({ data: { httpIntegrationResetToken, prometheusIntegrationResetToken } = {} } = {}) => {
            const error =
              httpIntegrationResetToken?.errors[0] || prometheusIntegrationResetToken?.errors[0];
            if (error) {
              return createFlash({ message: error });
            }

            const integration =
              httpIntegrationResetToken?.integration ||
              prometheusIntegrationResetToken?.integration;

            this.$apollo.mutate({
              mutation: updateCurrentIntergrationMutation,
              variables: {
                ...integration,
              },
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
    editIntegration({ id }) {
      const currentIntegration = this.integrations.list.find(integration => integration.id === id);
      this.$apollo.mutate({
        mutation: updateCurrentIntergrationMutation,
        variables: {
          id: currentIntegration.id,
          name: currentIntegration.name,
          active: currentIntegration.active,
          token: currentIntegration.token,
          type: currentIntegration.type,
          url: currentIntegration.url,
          apiUrl: currentIntegration.apiUrl,
        },
      });
    },
    deleteIntegration({ id }) {
      const { projectPath } = this;

      this.isUpdating = true;
      this.$apollo
        .mutate({
          mutation: destroyHttpIntegrationMutation,
          variables: {
            id,
          },
          update(store, { data }) {
            updateStoreAfterIntegrationDelete(store, getIntegrationsQuery, data, { projectPath });
          },
        })
        .then(({ data: { httpIntegrationDestroy } = {} } = {}) => {
          const error = httpIntegrationDestroy?.errors[0];
          if (error) {
            return createFlash({ message: error });
          }
          this.clearCurrentIntegration();
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
    clearCurrentIntegration() {
      this.$apollo.mutate({
        mutation: updateCurrentIntergrationMutation,
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
    <!-- TODO: Will be removed in 13.7 as part of: https://gitlab.com/gitlab-org/gitlab/-/issues/273657 -->
    <gl-alert v-if="opsgenie.active" :dismissible="false" variant="tip">
      <gl-sprintf
        :message="
          s__(
            'AlertSettings|We will soon be introducing the ability to create multiple unique HTTP endpoints. When this functionality is live,  you will be able to configure an integration with Opsgenie to surface Opsgenie alerts in GitLab. This will replace the current Opsgenie integration which will be deprecated. %{linkStart}More Information%{linkEnd}',
          )
        "
      >
        <template #link="{ content }">
          <gl-link
            class="gl-display-inline-block"
            href="https://gitlab.com/gitlab-org/gitlab/-/issues/273657"
            target="_blank"
            >{{ content }}</gl-link
          >
        </template>
      </gl-sprintf>
    </gl-alert>
    <integrations-list
      v-else
      :integrations="integrations.list"
      :loading="loading"
      @edit-integration="editIntegration"
      @delete-integration="deleteIntegration"
    />
    <alert-settings-form
      :loading="isUpdating"
      :can-add-integration="canAddIntegration"
      :can-manage-opsgenie="canManageOpsgenie"
      @create-new-integration="createNewIntegration"
      @update-integration="updateIntegration"
      @reset-token="resetToken"
      @clear-current-integration="clearCurrentIntegration"
      @set-test-alert-payload="setTestAlertPayload"
    />
  </div>
</template>
