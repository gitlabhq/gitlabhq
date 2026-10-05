<script>
import { INTEGRATION_VIEW_CONFIGS, INTEGRATION_EXTENSIONS_MARKETPLACE } from '../constants';
import IntegrationView from './integration_view.vue';
import ExtensionsMarketplaceWarning from './extensions_marketplace_warning.vue';

export default {
  name: 'ProfilePreferencesIntegrations',
  components: {
    IntegrationView,
    ExtensionsMarketplaceWarning,
  },
  inject: {
    integrationViews: {
      default: [],
    },
    userFields: {
      default: {},
    },
  },
  integrationViewConfigs: INTEGRATION_VIEW_CONFIGS,
  INTEGRATION_EXTENSIONS_MARKETPLACE,
  data() {
    const integrationValues = this.integrationViews.reduce((acc, { name }) => {
      const { formName } = INTEGRATION_VIEW_CONFIGS[name];

      acc[name] = Boolean(this.userFields[formName]);

      return acc;
    }, {});

    return {
      integrationValues,
    };
  },
  computed: {
    extensionsMarketplaceView() {
      return this.integrationViews.find(({ name }) => name === INTEGRATION_EXTENSIONS_MARKETPLACE);
    },
  },
};
</script>

<template>
  <div>
    <integration-view
      v-for="view in integrationViews"
      :key="view.name"
      v-model="integrationValues[view.name]"
      :help-link="view.help_link"
      :message="view.message"
      :message-url="view.message_url"
      :config="$options.integrationViewConfigs[view.name]"
      :title="view.title"
    />
    <extensions-marketplace-warning
      v-if="extensionsMarketplaceView"
      v-model="integrationValues[$options.INTEGRATION_EXTENSIONS_MARKETPLACE]"
      :help-url="extensionsMarketplaceView.help_link"
    />
  </div>
</template>
