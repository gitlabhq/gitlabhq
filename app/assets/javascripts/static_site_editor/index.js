import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import App from './components/app.vue';
import createStore from './store';
import createRouter from './router';
import createApolloProvider from './graphql';

const initStaticSiteEditor = el => {
  const { isSupportedContent, projectId, path: sourcePath, baseUrl } = el.dataset;
  const { current_username: username } = window.gon;
  const returnUrl = el.dataset.returnUrl || null;

  const store = createStore({
    initialState: {
      isSupportedContent: parseBoolean(isSupportedContent),
      projectId,
      returnUrl,
      sourcePath,
      username,
    },
  });
  const router = createRouter(baseUrl);
  const apolloProvider = createApolloProvider({
    isSupportedContent: parseBoolean(isSupportedContent),
    projectId,
    returnUrl,
    sourcePath,
    username,
  });

  return new Vue({
    el,
    store,
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
