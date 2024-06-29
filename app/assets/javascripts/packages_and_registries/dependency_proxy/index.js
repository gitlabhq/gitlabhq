import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import { apolloProvider } from '~/packages_and_registries/dependency_proxy/graphql';
import Translate from '~/vue_shared/translate';
import createRouter from './router';

Vue.use(Translate);

export const initDependencyProxyApp = () => {
  const el = document.getElementById('js-dependency-proxy');
  if (!el) {
    return null;
  }
  const { endpoint, groupPath, groupId, noManifestsIllustration, canClearCache, settingsPath } =
    el.dataset;
  return new Vue({
    el,
    apolloProvider,
    router: createRouter(endpoint),
    provide: {
      groupPath,
      groupId,
      noManifestsIllustration,
      canClearCache: parseBoolean(canClearCache),
      settingsPath,
    },
    render(createElement) {
      return createElement('router-view');
    },
  });
};
