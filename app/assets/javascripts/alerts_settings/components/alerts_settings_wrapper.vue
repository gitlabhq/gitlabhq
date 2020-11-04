<script>
import produce from 'immer';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { fetchPolicies } from '~/lib/graphql';
import createFlash, { FLASH_TYPES } from '~/flash';
import getIntegrationsQuery from '../graphql/queries/get_integrations.query.graphql';
import createHttpIntegrationMutation from '../graphql/mutations/create_http_integration.mutation.graphql';
import createPrometheusIntegrationMutation from '../graphql/mutations/create_prometheus_integration.mutation.graphql';
import IntegrationsList from './alerts_integrations_list.vue';
import SettingsFormOld from './alerts_settings_form_old.vue';
import SettingsFormNew from './alerts_settings_form_new.vue';
import { typeSet } from '../constants';

export default {
  typeSet,
  i18n: {
    changesSaved: s__(
      'AlertsIntegrations|The integration has been successfully saved. Alerts from this new integration should now appear on your alerts list.',
    ),
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
      error() {
        this.errored = true;
      },
    },
  },
  data() {
    return {
      errored: false,
      isUpdating: false,
      integrations: {},
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
    onCreateNewIntegration({ type, variables }) {
      this.isUpdating = true;
      this.$apollo
        .mutate({
          mutation:
            type === this.$options.typeSet.http
              ? createHttpIntegrationMutation
              : createPrometheusIntegrationMutation,
          variables: {
            ...variables,
            projectPath: this.projectPath,
          },
          update: this.updateIntegrations,
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
          this.errored = true;
          createFlash({ message: err });
        })
        .finally(() => {
          this.isUpdating = false;
        });
    },
    updateIntegrations(
      store,
      {
        data: { httpIntegrationCreate, prometheusIntegrationCreate },
      },
    ) {
      const integration =
        httpIntegrationCreate?.integration || prometheusIntegrationCreate?.integration;
      if (!integration) {
        return;
      }

      const sourceData = store.readQuery({
        query: getIntegrationsQuery,
        variables: {
          projectPath: this.projectPath,
        },
      });

      const data = produce(sourceData, draftData => {
        // eslint-disable-next-line no-param-reassign
        draftData.project.alertManagementIntegrations.nodes = [
          integration,
          ...draftData.project.alertManagementIntegrations.nodes,
        ];
      });

      store.writeQuery({
        query: getIntegrationsQuery,
        variables: {
          projectPath: this.projectPath,
        },
        data,
      });
    },
  },
};
</script>

<template>
  <div>
    <integrations-list
      :integrations="glFeatures.httpIntegrationsList ? integrations.list : intergrationsOptionsOld"
      :loading="loading"
    />
    <settings-form-new
      v-if="glFeatures.httpIntegrationsList"
      :loading="loading"
      @on-create-new-integration="onCreateNewIntegration"
    />
    <settings-form-old v-else />
  </div>
</template>
