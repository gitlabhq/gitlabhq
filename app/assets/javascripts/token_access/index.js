import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import TokenAccessApp from './components/token_access_app.vue';
import cacheConfig from './graphql/cache_config';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient({}, { cacheConfig }),
});

export const initTokenAccess = (containerId = 'js-ci-token-access-app') => {
  const containerEl = document.getElementById(containerId);

  if (!containerEl) {
    return false;
  }

  const { fullPath } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    name: 'TokenAccessAppsRoot',
    apolloProvider,
    provide: {
      fullPath,
    },
    render(createElement) {
      return createElement(TokenAccessApp);
    },
  });
};
