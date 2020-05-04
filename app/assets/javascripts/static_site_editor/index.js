import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import App from './components/app.vue';
import createStore from './store';
import createRouter from './router';

const initStaticSiteEditor = el => {
  const { isSupportedContent, projectId, path: sourcePath, returnUrl, baseUrl } = el.dataset;

  const store = createStore({
    initialState: {
      isSupportedContent: parseBoolean(isSupportedContent),
      projectId,
      returnUrl,
      sourcePath,
      username: window.gon.current_username,
    },
  });
  const router = createRouter(baseUrl);

  return new Vue({
    el,
    store,
    router,
    components: {
      App,
    },
    render(createElement) {
      return createElement('app');
    },
  });
};

export default initStaticSiteEditor;
