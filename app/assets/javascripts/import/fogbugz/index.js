import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import ImportFromFogBugzApp from './import_from_fogbugz_app.vue';

export function initFogbugzImportProjectForm() {
  const el = document.getElementById('js-vue-import-fogbugz-project-app');

  if (!el) {
    return null;
  }

  const { backButtonPath, formPath } = el.dataset;

  const props = { backButtonPath, formPath };

  return initVueApp({ el, name: 'ImportFromFogBugzRoot', component: ImportFromFogBugzApp, props });
}
