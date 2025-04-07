import Vue from 'vue';
import ImportManifestFileApp from './import_manifest_file_app.vue';

export function initManifestImportProjectForm() {
  const el = document.getElementById('js-vue-import-manifest-file-app');

  if (!el) {
    return null;
  }

  const { backButtonPath, formPath, statusImportManifestPath, namespaceId } = el.dataset;

  const props = {
    backButtonPath,
    formPath,
    statusImportManifestPath,
    namespaceId: namespaceId ? parseInt(namespaceId, 10) : null,
  };

  return new Vue({
    el,
    name: 'ImportManifestFileRoot',
    render(h) {
      return h(ImportManifestFileApp, { props });
    },
  });
}
