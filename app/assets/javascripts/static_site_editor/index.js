import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import StaticSiteEditor from './components/static_site_editor.vue';
import createStore from './store';

const initStaticSiteEditor = el => {
  const { isSupportedContent, projectId, path: sourcePath, returnUrl } = el.dataset;

  const store = createStore({
    initialState: {
      isSupportedContent: parseBoolean(isSupportedContent),
      projectId,
      returnUrl,
      sourcePath,
      username: window.gon.current_username,
    },
  });

  return new Vue({
    el,
    store,
    components: {
      StaticSiteEditor,
    },
    render(createElement) {
      return createElement('static-site-editor', StaticSiteEditor);
    },
  });
};

export default initStaticSiteEditor;
