import Vue from 'vue';
import StaticSiteEditor from './components/static_site_editor.vue';
import createStore from './store';

const initStaticSiteEditor = el => {
  const { projectId, path: sourcePath } = el.dataset;

  const store = createStore({
    initialState: { projectId, sourcePath, username: window.gon.current_username },
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
