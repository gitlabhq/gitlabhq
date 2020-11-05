import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import AlertSettingsWrapper from './components/alerts_settings_wrapper.vue';

Vue.use(VueApollo);

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
  } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(
      {},
      {
        cacheConfig: {},
      },
    ),
  });

  apolloProvider.clients.defaultClient.cache.writeData({
    data: {},
  });

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
