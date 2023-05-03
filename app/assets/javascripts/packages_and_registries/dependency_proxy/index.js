import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import app from '~/packages_and_registries/dependency_proxy/app.vue';
import { apolloProvider } from '~/packages_and_registries/dependency_proxy/graphql';
import Translate from '~/vue_shared/translate';

Vue.use(Translate);

export const initDependencyProxyApp = () => {
  const el = document.getElementById('js-dependency-proxy');
  if (!el) {
    return null;
  }
  const { groupPath, groupId, noManifestsIllustration, canClearCache, settingsPath } = el.dataset;
  return new Vue({
    el,
    apolloProvider,
    provide: {
      groupPath,
      groupId,
      noManifestsIllustration,
      canClearCache: parseBoolean(canClearCache),
      settingsPath,
    },
    render(createElement) {
      return createElement(app);
    },
  });
};
