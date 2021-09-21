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
  const { dependencyProxyAvailable, ...dataset } = el.dataset;
  return new Vue({
    el,
    apolloProvider,
    provide: {
      dependencyProxyAvailable: parseBoolean(dependencyProxyAvailable),
      ...dataset,
    },
    render(createElement) {
      return createElement(app);
    },
  });
};
