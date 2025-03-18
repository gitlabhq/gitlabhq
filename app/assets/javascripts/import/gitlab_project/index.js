import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import importFromGitlabExportApp from './import_from_gitlab_export_app.vue';

export function initGitLabImportProjectForm() {
  const el = document.getElementById('js-import-gitlab-project-root');

  if (!el) {
    return null;
  }

  const {
    backButtonPath,
    namespaceFullPath,
    namespaceId,
    rootPath,
    importGitlabProjectPath,
    userNamespaceId,
    canCreateProject,
    rootUrl,
  } = el.dataset;

  const props = {
    backButtonPath,
    namespaceFullPath,
    namespaceId,
    rootPath,
    importGitlabProjectPath,
  };

  const provide = {
    userNamespaceId,
    canCreateProject,
    rootUrl,
  };

  return new Vue({
    el,
    name: 'ImportGitLabProjectRoot',
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    provide,
    render(h) {
      return h(importFromGitlabExportApp, { props });
    },
  });
}
