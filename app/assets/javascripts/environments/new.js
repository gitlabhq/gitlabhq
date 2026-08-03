import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { removeLastSlashInUrlPath } from '~/lib/utils/url_utility';
import NewEnvironment from './components/new_environment.vue';
import { apolloProvider } from './graphql/client';

Vue.use(VueApollo);

export default (el) => {
  if (!el) {
    return null;
  }

  const { projectEnvironmentsPath, projectPath, markdownPreviewPath, kasTunnelUrl } = el.dataset;

  return initVueApp({
    el,
    name: 'NewEnvironmentRoot',
    apolloProvider: apolloProvider(),
    provide: {
      projectEnvironmentsPath,
      projectPath,
      markdownPreviewPath,
      kasTunnelUrl: removeLastSlashInUrlPath(kasTunnelUrl),
    },
    component: NewEnvironment,
  });
};
