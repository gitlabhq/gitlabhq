import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
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
      projectShortPath,
    } = headerEl.dataset;

    initClientQueries({ projectPath, projectShortPath, ref, escapedRef });

    // eslint-disable-next-line no-new
    new Vue({
      el: headerEl,
      provide: {
        canCollaborate: parseBoolean(breadcrumbsCanCollaborate),
        canEditTree: parseBoolean(breadcrumbsCanEditTree),
        canPushCode: parseBoolean(breadcrumbsCanPushCode),
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
        isBlobView,
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
