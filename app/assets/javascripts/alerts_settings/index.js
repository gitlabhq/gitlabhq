import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import AlertSettingsWrapper from './components/alerts_settings_wrapper.vue';
import apolloProvider from './graphql';
import getCurrentIntegrationQuery from './graphql/queries/get_current_integration.query.graphql';

apolloProvider.clients.defaultClient.cache.writeQuery({
  query: getCurrentIntegrationQuery,
  data: {
    currentIntegration: null,
  },
});

Vue.use(GlToast);

export default (el) => {
  if (!el) {
    return null;
  }

  const { alertsUsageUrl, projectPath, multiIntegrations, alertFields } = el.dataset;

  return new Vue({
    el,
    components: {
      AlertSettingsWrapper,
    },
    provide: {
      alertsUsageUrl,
      projectPath,
      multiIntegrations: parseBoolean(multiIntegrations),
    },
    apolloProvider,
    render(createElement) {
      return createElement('alert-settings-wrapper', {
        props: {
          alertFields: parseBoolean(multiIntegrations) ? JSON.parse(alertFields) : null,
        },
      });
    },
  });
};
