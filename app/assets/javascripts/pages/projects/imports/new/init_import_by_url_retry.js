import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { parseBoolean } from '~/lib/utils/common_utils';
import ImportByUrlToExistingProjectForm from '~/projects/new_v2/components/import_by_url_to_existing_project_form.vue';

export function initImportByUrlRetry() {
  const el = document.querySelector('.js-vue-import-by-url-to-project-root');

  if (!el) return null;

  const {
    importByUrlValidatePath,
    importFromUrl,
    importPath,
    gitTimeout,
    ciCdOnly,
    hasRepositoryMirrorsFeature,
  } = el.dataset;

  const provide = {
    importByUrlValidatePath,
    importFromUrl,
    importPath,
    gitTimeout,
    ciCdOnly: parseBoolean(ciCdOnly),
    hasRepositoryMirrorsFeature: parseBoolean(hasRepositoryMirrorsFeature),
  };

  return initVueApp({
    el,
    name: 'ImportByUrlToExistingProjectRoot',
    provide,
    component: ImportByUrlToExistingProjectForm,
  });
}
