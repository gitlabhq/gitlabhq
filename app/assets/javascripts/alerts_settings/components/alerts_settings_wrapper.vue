<script>
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { fetchPolicies } from '~/lib/graphql';
import createFlash, { FLASH_TYPES } from '~/flash';
import getIntegrationsQuery from '../graphql/queries/get_integrations.query.graphql';
import createHttpIntegrationMutation from '../graphql/mutations/create_http_integration.mutation.graphql';
import createPrometheusIntegrationMutation from '../graphql/mutations/create_prometheus_integration.mutation.graphql';
import updateHttpIntegrationMutation from '../graphql/mutations/update_http_integration.mutation.graphql';
import updatePrometheusIntegrationMutation from '../graphql/mutations/update_prometheus_integration.mutation.graphql';
import destroyHttpIntegrationMutation from '../graphql/mutations/destroy_http_integration.mutation.graphql';
import resetHttpTokenMutation from '../graphql/mutations/reset_http_token.mutation.graphql';
import resetPrometheusTokenMutation from '../graphql/mutations/reset_prometheus_token.mutation.graphql';
import IntegrationsList from './alerts_integrations_list.vue';
import SettingsFormOld from './alerts_settings_form_old.vue';
import SettingsFormNew from './alerts_settings_form_new.vue';
import { typeSet } from '../constants';
import {
  updateStoreAfterIntegrationDelete,
  updateStoreAfterIntegrationAdd,
} from '../utils/cache_updates';

export default {
  typeSet,
  i18n: {
    changesSaved: s__(
      'AlertsIntegrations|The integration has been successfully saved. Alerts from this new integration should now appear on your alerts list.',
    ),
    integrationRemoved: s__('AlertsIntegrations|The integration has been successfully removed.'),
  },
  components: {
    IntegrationsList,
    SettingsFormOld,
    SettingsFormNew,
  },
  mixins: [glFeatureFlagsMixin()],
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
  },
  data() {
    return {
      isUpdating: false,
      integrations: {},
      currentIntegration: null,
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.integrations.loading;
    },
    intergrationsOptionsOld() {
      return [
        {
          name: s__('AlertSettings|HTTP endpoint'),
          type: s__('AlertsIntegrations|HTTP endpoint'),
          active: this.generic.active,
        },
        {
          name: s__('AlertSettings|External Prometheus'),
          type: s__('AlertsIntegrations|Prometheus'),
          active: this.prometheus.active,
        },
      ];
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
          return createFlash({
            message: this.$options.i18n.changesSaved,
            type: FLASH_TYPES.SUCCESS,
          });
        })
        .catch(err => {
          createFlash({ message: err });
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
          return createFlash({
            message: this.$options.i18n.changesSaved,
            type: FLASH_TYPES.SUCCESS,
          });
        })
        .catch(err => {
          createFlash({ message: err });
        })
        .finally(() => {
          this.isUpdating = false;
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
            this.currentIntegration = integration;

            return createFlash({
              message: this.$options.i18n.changesSaved,
              type: FLASH_TYPES.SUCCESS,
            });
          },
        )
        .catch(err => {
          createFlash({ message: err });
        })
        .finally(() => {
          this.isUpdating = false;
        });
    },
    editIntegration({ id }) {
      this.currentIntegration = this.integrations.list.find(integration => integration.id === id);
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
          this.currentIntegration = null;
          return createFlash({
            message: this.$options.i18n.integrationRemoved,
            type: FLASH_TYPES.SUCCESS,
          });
        })
        .catch(err => {
          this.errored = true;
          createFlash({ message: err });
        })
        .finally(() => {
          this.isUpdating = false;
        });
    },
    clearCurrentIntegration() {
      this.currentIntegration = null;
    },
  },
};
</script>

<template>
  <div>
    <integrations-list
      :integrations="glFeatures.httpIntegrationsList ? integrations.list : intergrationsOptionsOld"
      :loading="loading"
      @edit-integration="editIntegration"
      @delete-integration="deleteIntegration"
    />
    <settings-form-new
      v-if="glFeatures.httpIntegrationsList"
      :loading="isUpdating"
      :current-integration="currentIntegration"
      @create-new-integration="createNewIntegration"
      @update-integration="updateIntegration"
      @reset-token="resetToken"
      @clear-current-integration="clearCurrentIntegration"
    />
    <settings-form-old v-else />
  </div>
</template>
