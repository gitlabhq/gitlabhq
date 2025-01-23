import Vue from 'vue';
import { provideWebIdeLink } from 'ee_else_ce/pages/projects/shared/web_ide_link/provide_web_ide_link';
import { parseBoolean, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import apolloProvider from './graphql';
import projectShortPathQuery from './queries/project_short_path.query.graphql';
import projectPathQuery from './queries/project_path.query.graphql';
import HeaderArea from './components/header_area.vue';
import createRouter from './router';
import refsQuery from './queries/ref.query.graphql';

const initClientQueries = ({ projectPath, projectShortPath, ref, escapedRef }) => {
  // These queries are used in the breadcrumbs component as GraphQL client queries.

  if (projectPath)
    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: projectPathQuery,
      data: { projectPath },
    });

  if (projectShortPath)
    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: projectShortPathQuery,
      data: { projectShortPath },
    });

  if (ref || escapedRef)
    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: refsQuery,
      data: { ref, escapedRef },
    });
};

export default function initHeaderApp({ router, isReadmeView = false, isBlobView = false }) {
  const headerEl = document.getElementById('js-repository-blob-header-app');
  if (headerEl) {
    const {
      ref,
      escapedRef,
      refType,
      projectId,
      breadcrumbsCanCollaborate,
      breadcrumbsCanEditTree,
      breadcrumbsCanPushCode,
      breadcrumbsCanPushToBranch,
      breadcrumbsSelectedBranch,
      breadcrumbsNewBranchPath,
      breadcrumbsNewTagPath,
      breadcrumbsNewBlobPath,
      breadcrumbsForkNewBlobPath,
      breadcrumbsForkNewDirectoryPath,
      breadcrumbsForkUploadBlobPath,
      breadcrumbsUploadPath,
      breadcrumbsNewDirPath,
      projectRootPath,
      comparePath,
      projectPath,
      webIdeButtonOptions,
      sshUrl,
      httpUrl,
      xcodeUrl,
      kerberosUrl,
      downloadLinks,
      downloadArtifacts,
      projectShortPath,
      isBinary,
      ...options
    } = headerEl.dataset;

    const {
      isFork,
      needsToFork,
      gitpodEnabled,
      isBlob,
      showEditButton,
      showWebIdeButton,
      showGitpodButton,
      showPipelineEditorUrl,
      webIdeUrl,
      editUrl,
      pipelineEditorUrl,
      gitpodUrl,
      userPreferencesGitpodPath,
      userProfileEnableGitpodPath,
    } = convertObjectPropsToCamelCase(webIdeButtonOptions ? JSON.parse(webIdeButtonOptions) : {});

    initClientQueries({ projectPath, projectShortPath, ref, escapedRef });

    // eslint-disable-next-line no-new
    new Vue({
      el: headerEl,
      provide: {
        canCollaborate: parseBoolean(breadcrumbsCanCollaborate),
        canEditTree: parseBoolean(breadcrumbsCanEditTree),
        canPushCode: parseBoolean(breadcrumbsCanPushCode),
        canPushToBranch: parseBoolean(breadcrumbsCanPushToBranch),
        originalBranch: ref,
        selectedBranch: breadcrumbsSelectedBranch,
        newBranchPath: breadcrumbsNewBranchPath,
        newTagPath: breadcrumbsNewTagPath,
        newBlobPath: breadcrumbsNewBlobPath,
        forkNewBlobPath: breadcrumbsForkNewBlobPath,
        forkNewDirectoryPath: breadcrumbsForkNewDirectoryPath,
        forkUploadBlobPath: breadcrumbsForkUploadBlobPath,
        uploadPath: breadcrumbsUploadPath,
        newDirPath: breadcrumbsNewDirPath,
        projectRootPath,
        projectShortPath,
        comparePath,
        isReadmeView,
        isFork: parseBoolean(isFork),
        needsToFork: parseBoolean(needsToFork),
        gitpodEnabled: parseBoolean(gitpodEnabled),
        isBlob: parseBoolean(isBlob),
        showEditButton: parseBoolean(showEditButton),
        showWebIdeButton: parseBoolean(showWebIdeButton),
        showGitpodButton: parseBoolean(showGitpodButton),
        showPipelineEditorUrl: parseBoolean(showPipelineEditorUrl),
        webIdeUrl,
        editUrl,
        pipelineEditorUrl,
        gitpodUrl,
        userPreferencesGitpodPath,
        userProfileEnableGitpodPath,
        httpUrl,
        xcodeUrl,
        sshUrl,
        kerberosUrl,
        downloadLinks: downloadLinks ? JSON.parse(downloadLinks) : null,
        downloadArtifacts: downloadArtifacts ? JSON.parse(downloadArtifacts) : [],
        isBlobView,
        isBinary: parseBoolean(isBinary),
        ...provideWebIdeLink(options),
      },
      apolloProvider,
      router: router || createRouter(projectPath, escapedRef),
      render(h) {
        return h(HeaderArea, {
          props: {
            refType,
            currentRef: ref,
            // BlobControls:
            projectPath,
            // RefSelector:
            projectId,
          },
        });
      },
    });
  }
}
