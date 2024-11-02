import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import TokenAccessApp from './components/token_access_app.vue';
import cacheConfig from './graphql/cache_config';

Vue.use(VueApollo);
Vue.use(GlToast);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient({}, { cacheConfig }),
});

export const initTokenAccess = (containerId = 'js-ci-token-access-app') => {
  const containerEl = document.getElementById(containerId);

  if (!containerEl) {
    return false;
  }

  const { fullPath, csvDownloadPath, enforceAllowlist } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    name: 'TokenAccessAppsRoot',
    apolloProvider,
    provide: {
      enforceAllowlist: JSON.parse(enforceAllowlist),
      fullPath,
      csvDownloadPath,
    },
    render(createElement) {
      return createElement(TokenAccessApp);
    },
  });
};
