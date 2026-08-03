import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { parseBoolean } from '../lib/utils/common_utils';
import ProjectFormGroup from './components/project_form_group.vue';
import state from './state';

export function isConfidentialIssue() {
  return parseBoolean(document.querySelector('.js-create-mr').dataset.isConfidential);
}

export function canCreateConfidentialMergeRequest() {
  return isConfidentialIssue() && Object.keys(state.selectedProject).length > 0;
}

export function init() {
  const el = document.getElementById('js-forked-project');

  return initVueApp({
    el,
    name: 'ProjectFormGroupRoot',
    component: ProjectFormGroup,
    props: {
      namespacePath: el.dataset.namespacePath,
      projectPath: el.dataset.projectPath,
      newForkPath: el.dataset.newForkPath,
      helpPagePath: el.dataset.helpPagePath,
    },
  });
}
