import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import App from './components/app.vue';
import createRouter from './router';
import createApolloProvider from './graphql';

const initStaticSiteEditor = el => {
  const { isSupportedContent, path: sourcePath, baseUrl, namespace, project } = el.dataset;
  const { current_username: username } = window.gon;
  const returnUrl = el.dataset.returnUrl || null;

  const router = createRouter(baseUrl);
  const apolloProvider = createApolloProvider({
    isSupportedContent: parseBoolean(isSupportedContent),
    project: `${namespace}/${project}`,
    returnUrl,
    sourcePath,
    username,
  });

  return new Vue({
    el,
    router,
    apolloProvider,
    components: {
      App,
    },
    render(createElement) {
      return createElement('app');
    },
  });
};

export default initStaticSiteEditor;
