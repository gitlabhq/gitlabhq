import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import ImportFromGithubApp from './import_from_github_app.vue';

export function initGitHubImportProjectForm() {
  const el = document.getElementById('js-vue-import-github-project-app');

  if (!el) {
    return null;
  }

  const { viewModel } = el.dataset;
  const provide = JSON.parse(viewModel);

  return initVueApp({
    el,
    name: 'ImportFromGitHubRoot',
    provide: convertObjectPropsToCamelCase(provide),
    component: ImportFromGithubApp,
  });
}
