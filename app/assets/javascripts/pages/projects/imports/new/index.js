import Vue from 'vue';
import initProjectNew from '~/projects/project_new';
import ImportByUrlToExistingProjectForm from '~/projects/new_v2/components/import_by_url_to_existing_project_form.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

initProjectNew.bindEvents();

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

  return new Vue({
    el,
    name: 'ImportByUrlToExistingProjectRoot',
    provide,
    render(createElement) {
      return createElement(ImportByUrlToExistingProjectForm);
    },
  });
}

initImportByUrlRetry();
