import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { parseBoolean } from '~/lib/utils/common_utils';
import createDefaultClient from '~/lib/graphql';
import NewProjectFormApp from './components/app.vue';

export function initNewProjectForm() {
  const el = document.getElementById('js-vue-new-project-app');

  if (!el) {
    return null;
  }

  const {
    namespaceFullPath,
    namespaceId,
    userNamespaceId,
    userNamespaceFullPath,
    newProjectGuidelines,
    pushToCreateProjectCommand,
    rootPath,
    projectsUrl,
    parentGroupUrl,
    parentGroupName,
    isCiCdAvailable,
    canImportProjects,
    importSourcesEnabled,
    trackLabel,
    canSelectNamespace,
    canCreateProject,
    userProjectLimit,
    displaySha256Repository,
    restrictedVisibilityLevels,
    defaultProjectVisibility,
    importHistoryPath,
    importGitlabEnabled,
    importGitlabImportPath,
    importGithubEnabled,
    importGithubImportPath,
    importBitbucketEnabled,
    importBitbucketImportPath,
    importBitbucketImportConfigured,
    importBitbucketDisabledMessage,
    importBitbucketServerEnabled,
    importBitbucketServerImportPath,
    importFogbugzEnabled,
    importFogbugzImportPath,
    importGiteaEnabled,
    importGiteaImportPath,
    importGitEnabled,
    importManifestEnabled,
    importManifestImportPath,
    importByUrlValidatePath,
  } = el.dataset;

  const provide = {
    namespaceFullPath,
    namespaceId,
    userNamespaceId,
    userNamespaceFullPath,
    newProjectGuidelines,
    pushToCreateProjectCommand,
    rootPath,
    projectsUrl,
    parentGroupUrl,
    parentGroupName,
    trackLabel,
    isCiCdAvailable: parseBoolean(isCiCdAvailable),
    importSourcesEnabled: parseBoolean(importSourcesEnabled),
    canImportProjects: parseBoolean(canImportProjects),
    canSelectNamespace: parseBoolean(canSelectNamespace),
    canCreateProject: parseBoolean(canCreateProject),
    userProjectLimit: parseInt(userProjectLimit, 10),
    displaySha256Repository: parseBoolean(displaySha256Repository),
    restrictedVisibilityLevels: JSON.parse(restrictedVisibilityLevels),
    defaultProjectVisibility,
    importHistoryPath,
    importGitlabEnabled: parseBoolean(importGitlabEnabled),
    importGitlabImportPath,
    importGithubEnabled: parseBoolean(importGithubEnabled),
    importGithubImportPath,
    importBitbucketEnabled: parseBoolean(importBitbucketEnabled),
    importBitbucketImportPath,
    importBitbucketImportConfigured: parseBoolean(importBitbucketImportConfigured),
    importBitbucketDisabledMessage,
    importBitbucketServerEnabled: parseBoolean(importBitbucketServerEnabled),
    importBitbucketServerImportPath,
    importFogbugzEnabled: parseBoolean(importFogbugzEnabled),
    importFogbugzImportPath,
    importGiteaEnabled: parseBoolean(importGiteaEnabled),
    importGiteaImportPath,
    importGitEnabled: parseBoolean(importGitEnabled),
    importManifestEnabled: parseBoolean(importManifestEnabled),
    importManifestImportPath,
    importByUrlValidatePath,
  };

  return new Vue({
    el,
    name: 'NewProjectFormRoot',
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    provide,
    render(h) {
      return h(NewProjectFormApp);
    },
  });
}
