import Vue from 'vue';
import StaticSiteEditor from './components/static_site_editor.vue';
import createStore from './store';

const initStaticSiteEditor = el => {
  const { projectId, returnUrl, path: sourcePath } = el.dataset;

  const store = createStore({
    initialState: { projectId, returnUrl, sourcePath, username: window.gon.current_username },
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
