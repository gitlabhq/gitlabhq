import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';

import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import App from './components/app.vue';

export const initOrganizationsProjectsEdit = () => {
  const el = document.getElementById('js-organizations-projects-edit');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;
  const { projectsOrganizationPath, previewMarkdownPath, project } = convertObjectPropsToCamelCase(
    JSON.parse(appData),
    { deep: true },
  );

  return initVueApp({
    el,
    name: 'OrganizationProjectsEditRoot',
    provide: {
      projectsOrganizationPath,
      previewMarkdownPath,
      project,
    },
    component: App,
  });
};
