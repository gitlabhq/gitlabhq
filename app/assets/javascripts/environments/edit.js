import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { removeLastSlashInUrlPath } from '~/lib/utils/url_utility';
import EditEnvironment from './components/edit_environment.vue';
import { apolloProvider } from './graphql/client';

Vue.use(VueApollo);

export default (el) => {
  if (!el) {
    return null;
  }

  const {
    projectEnvironmentsPath,
    protectedEnvironmentSettingsPath,
    projectPath,
    markdownPreviewPath,
    environmentName,
    kasTunnelUrl,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider: apolloProvider(),
    provide: {
      projectEnvironmentsPath,
      protectedEnvironmentSettingsPath,
      projectPath,
      markdownPreviewPath,
      environmentName,
      kasTunnelUrl: removeLastSlashInUrlPath(kasTunnelUrl),
    },
    render(h) {
      return h(EditEnvironment);
    },
  });
};
