import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { removeLastSlashInUrlPath } from '~/lib/utils/url_utility';
import NewEnvironment from './components/new_environment.vue';
import { apolloProvider } from './graphql/client';

Vue.use(VueApollo);

export default (el) => {
  if (!el) {
    return null;
  }

  const { projectEnvironmentsPath, projectPath, markdownPreviewPath, kasTunnelUrl } = el.dataset;

  return new Vue({
    el,
    apolloProvider: apolloProvider(),
    provide: {
      projectEnvironmentsPath,
      projectPath,
      markdownPreviewPath,
      kasTunnelUrl: removeLastSlashInUrlPath(kasTunnelUrl),
    },
    render(h) {
      return h(NewEnvironment);
    },
  });
};
