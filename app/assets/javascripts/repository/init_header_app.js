import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import apolloProvider from './graphql';
import HeaderArea from './components/header_area.vue';
import createRouter from './router';

export default function initHeaderApp(isReadmeView = false) {
  const headerEl = document.getElementById('js-repository-blob-header-app');
  if (headerEl) {
    const {
      historyLink,
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
    } = headerEl.dataset;

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
        comparePath,
        isReadmeView,
      },
      apolloProvider,
      router: createRouter(projectPath, escapedRef),
      render(h) {
        return h(HeaderArea, {
          props: {
            refType,
            currentRef: ref,
            historyLink,
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
