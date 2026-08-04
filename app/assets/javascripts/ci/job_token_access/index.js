import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import TokenAccessApp from './components/token_access_app.vue';
import cacheConfig from './graphql/cache_config';

Vue.use(VueApollo);
Vue.use(GlToast);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient({}, { cacheConfig }),
});

export const initJobTokenAccess = (containerId = 'js-ci-job-token-access-app') => {
  const containerEl = document.getElementById(containerId);

  if (!containerEl) {
    return false;
  }

  const { csvDownloadPath, enforceAllowlist, fullPath } = containerEl.dataset;

  return initVueApp({
    el: containerEl,
    name: 'TokenAccessAppsRoot',
    apolloProvider,
    provide: {
      csvDownloadPath,
      enforceAllowlist: JSON.parse(enforceAllowlist),
      fullPath,
    },
    component: TokenAccessApp,
  });
};
