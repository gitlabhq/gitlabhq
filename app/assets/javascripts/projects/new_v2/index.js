import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import NewProjectFormApp from './components/app.vue';

export function initNewProjectForm() {
  const el = document.getElementById('js-vue-new-project-app');

  if (!el) {
    return null;
  }

  const {
    pushToCreateProjectCommand,
    projectHelpPath,
    hasErrors,
    isCiCdAvailable,
    parentGroupUrl,
    parentGroupName,
    rootPath,
    projectsUrl,
    canImportProjects,
    importSourcesEnabled,
    namespaceFullPath,
    namespaceId,
    userNamespaceId,
    trackLabel,
  } = el.dataset;

  const props = {
    hasErrors: parseBoolean(hasErrors),
    isCiCdAvailable: parseBoolean(isCiCdAvailable),
    parentGroupUrl,
    parentGroupName,
    rootPath,
    projectsUrl,
    canImportProjects: parseBoolean(canImportProjects),
    importSourcesEnabled: parseBoolean(importSourcesEnabled),
    namespaceFullPath,
    namespaceId,
    userNamespaceId,
    trackLabel,
  };

  const provide = {
    projectHelpPath,
    pushToCreateProjectCommand,
  };

  return new Vue({
    el,
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    provide,
    render(h) {
      return h(NewProjectFormApp, { props });
    },
  });
}
