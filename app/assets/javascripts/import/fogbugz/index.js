import Vue from 'vue';
import ImportFromFogBugzApp from './import_from_fogbugz_app.vue';

export function initFogbugzImportProjectForm() {
  const el = document.getElementById('js-vue-import-fogbugz-project-app');

  if (!el) {
    return null;
  }

  const { backButtonPath, formPath } = el.dataset;

  const props = { backButtonPath, formPath };

  return new Vue({
    el,
    name: 'ImportFromFogBugzRoot',
    render(createElement) {
      return createElement(ImportFromFogBugzApp, { props });
    },
  });
}
