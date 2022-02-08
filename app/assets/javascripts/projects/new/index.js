import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import NewProjectCreationApp from './components/app.vue';
import NewProjectUrlSelect from './components/new_project_url_select.vue';
import DeploymentTargetSelect from './components/deployment_target_select.vue';

export function initNewProjectCreation() {
  const el = document.querySelector('.js-new-project-creation');

  const {
    pushToCreateProjectCommand,
    workingWithProjectsHelpPath,
    newProjectGuidelines,
    hasErrors,
    isCiCdAvailable,
  } = el.dataset;

  const props = {
    hasErrors: parseBoolean(hasErrors),
    isCiCdAvailable: parseBoolean(isCiCdAvailable),
    newProjectGuidelines,
  };

  const provide = {
    workingWithProjectsHelpPath,
    pushToCreateProjectCommand,
  };

  return new Vue({
    el,
    provide,
    render(h) {
      return h(NewProjectCreationApp, { props });
    },
  });
}

export function initNewProjectUrlSelect() {
  const elements = document.querySelectorAll('.js-vue-new-project-url-select');

  if (!elements.length) {
    return;
  }

  Vue.use(VueApollo);

  elements.forEach(
    (el) =>
      new Vue({
        el,
        apolloProvider: new VueApollo({
          defaultClient: createDefaultClient(),
        }),
        provide: {
          namespaceFullPath: el.dataset.namespaceFullPath,
          namespaceId: el.dataset.namespaceId,
          rootUrl: el.dataset.rootUrl,
          trackLabel: el.dataset.trackLabel,
          userNamespaceFullPath: el.dataset.userNamespaceFullPath,
          userNamespaceId: el.dataset.userNamespaceId,
        },
        render: (createElement) => createElement(NewProjectUrlSelect),
      }),
  );
}

export function initDeploymentTargetSelect() {
  const el = document.querySelector('.js-deployment-target-select');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    render: (createElement) => createElement(DeploymentTargetSelect),
  });
}
