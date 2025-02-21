import Vue from 'vue';
import importFromBitbucketServerApp from './import_from_bitbucket_server_app.vue';

export function initBitbucketServerImportProjectForm() {
  const el = document.getElementById('js-vue-import-bitbucket-server-project-root');

  if (!el) {
    return null;
  }

  const { backButtonPath, formPath } = el.dataset;

  const props = { backButtonPath, formPath };

  return new Vue({
    el,
    name: 'ImportFromBitbucketServerRoot',
    render(h) {
      return h(importFromBitbucketServerApp, { props });
    },
  });
}
