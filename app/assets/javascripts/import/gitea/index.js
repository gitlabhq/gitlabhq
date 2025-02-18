import Vue from 'vue';
import ImportFromGiteaRoot from './import_from_gitea_root.vue';

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
      return h(ImportFromGiteaRoot, { props });
    },
  });
}
