import Vue from 'vue';
import ImportFromGiteaApp from './import_from_gitea_app.vue';

export function initGiteaImportProjectForm() {
  const el = document.getElementById('js-vue-import-gitea-project-root');

  if (!el) {
    return null;
  }

  const { backButtonPath, namespaceId, formPath } = el.dataset;

  const props = { backButtonPath, namespaceId, formPath };

  return new Vue({
    el,
    name: 'ImportFromGiteaRoot',
    render(h) {
      return h(ImportFromGiteaApp, { props });
    },
  });
}
