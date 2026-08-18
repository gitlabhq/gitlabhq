import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import initAccordion from '~/accordion';
import NewProjectCreationApp from './components/app.vue';
import NewProjectUrlSelect from './components/new_project_url_select.vue';
import DeploymentTargetSelect from './components/deployment_target_select.vue';

export function initNewProjectCreation() {
  const el = document.querySelector('.js-new-project-creation');

  if (!el) {
    return null;
  }

  const {
    pushToCreateProjectCommand,
    newProjectGuidelines,
    hasErrors,
    isCiCdAvailable,
    parentGroupUrl,
    parentGroupName,
    projectsUrl,
    rootPath,
    canImportProjects,
    showBuiltInProjectTemplates,
  } = el.dataset;

  const props = {
    hasErrors: parseBoolean(hasErrors),
    isCiCdAvailable: parseBoolean(isCiCdAvailable),
    newProjectGuidelines,
    parentGroupUrl,
    parentGroupName,
    projectsUrl,
    rootPath,
    canImportProjects: parseBoolean(canImportProjects),
    showBuiltInProjectTemplates: parseBoolean(showBuiltInProjectTemplates),
  };

  const provide = {
    pushToCreateProjectCommand,
  };

  return initVueApp({
    el,
    name: 'NewProjectCreationAppRoot',
    provide,
    component: NewProjectCreationApp,
    props,
  });
}

export function initNewProjectUrlSelect() {
  const elements = document.querySelectorAll('.js-vue-new-project-url-select');

  if (!elements.length) {
    return;
  }

  Vue.use(VueApollo);

  elements.forEach((el) =>
    initVueApp({
      el,
      name: 'NewProjectUrlSelectRoot',
      apolloProvider: new VueApollo({
        defaultClient: createDefaultClient(),
      }),
      provide: {
        namespaceFullPath: el.dataset.namespaceFullPath,
        namespaceId: el.dataset.namespaceId,
        rootUrl: el.dataset.rootUrl,
        trackLabel: el.dataset.trackLabel,
        userNamespaceId: el.dataset.userNamespaceId,
        inputId: el.dataset.inputId,
        inputName: el.dataset.inputName,
      },
      component: NewProjectUrlSelect,
    }),
  );
}

export function initDeploymentTargetSelect() {
  const el = document.querySelector('.js-deployment-target-select');

  if (!el) {
    return null;
  }

  return initVueApp({ el, name: 'DeploymentTargetSelectRoot', component: DeploymentTargetSelect });
}

initAccordion(document.getElementById('js-experimental-setting-accordion'));
