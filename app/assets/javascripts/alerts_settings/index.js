import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';
import AlertSettingsWrapper from './components/alerts_settings_wrapper.vue';
import apolloProvider from './graphql';

apolloProvider.clients.defaultClient.cache.writeData({
  data: {
    currentIntegration: null,
  },
});
Vue.use(GlToast);

export default el => {
  if (!el) {
    return null;
  }

  const {
    prometheusActivated,
    prometheusUrl,
    prometheusAuthorizationKey,
    prometheusFormPath,
    prometheusResetKeyPath,
    prometheusApiUrl,
    activated: activatedStr,
    alertsSetupUrl,
    alertsUsageUrl,
    formPath,
    authorizationKey,
    url,
    opsgenieMvcAvailable,
    opsgenieMvcFormPath,
    opsgenieMvcEnabled,
    opsgenieMvcTargetUrl,
    projectPath,
    multiIntegrations,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      prometheus: {
        active: parseBoolean(prometheusActivated),
        url: prometheusUrl,
        token: prometheusAuthorizationKey,
        prometheusFormPath,
        prometheusResetKeyPath,
        prometheusApiUrl,
      },
      generic: {
        alertsSetupUrl,
        alertsUsageUrl,
        active: parseBoolean(activatedStr),
        formPath,
        token: authorizationKey,
        url,
      },
      opsgenie: {
        formPath: opsgenieMvcFormPath,
        active: parseBoolean(opsgenieMvcEnabled),
        opsgenieMvcTargetUrl,
        opsgenieMvcIsAvailable: parseBoolean(opsgenieMvcAvailable),
      },
      projectPath,
      multiIntegrations: parseBoolean(multiIntegrations),
    },
    apolloProvider,
    components: {
      AlertSettingsWrapper,
    },
    render(createElement) {
      return createElement('alert-settings-wrapper');
    },
  });
};
