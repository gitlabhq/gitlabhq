<script>
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import IntegrationsList from './alerts_integrations_list.vue';
import SettingsFormOld from './alerts_settings_form_old.vue';
import SettingsFormNew from './alerts_settings_form_new.vue';

export default {
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
  },
  computed: {
    integrations() {
      return [
        {
          name: s__('AlertSettings|HTTP endpoint'),
          type: s__('AlertsIntegrations|HTTP endpoint'),
          activated: this.generic.activated,
        },
        {
          name: s__('AlertSettings|External Prometheus'),
          type: s__('AlertsIntegrations|Prometheus'),
          activated: this.prometheus.activated,
        },
      ];
    },
  },
};
</script>

<template>
  <div>
    <integrations-list :integrations="integrations" />
    <settings-form-new v-if="glFeatures.httpIntegrationsList" />
    <settings-form-old v-else />
  </div>
</template>
