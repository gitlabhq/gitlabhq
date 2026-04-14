import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import RepositoryApp from '~/repository/components/app.vue';
import createStore from '~/code_navigation/store';

export default function initRepositoryApp(router, apolloProvider, options = {}) {
  const viewBlobEl = document.querySelector('#js-view-blob-app');
  const {
    blobPath,
    projectPath,
    refType,
    targetBranch,
    originalBranch,
    resourceId,
    userId,
    explainCodeAvailable,
    canDownloadCode,
    hasRevsFile,
    highlightWorker,
    webIdeLinkData: { newWorkspacePath } = {},
  } = options;

  if (!viewBlobEl || !blobPath || !projectPath || !highlightWorker) return null;

  return new Vue({
    el: viewBlobEl,
    name: 'RepositoryAppRoot',
    store: createStore(),
    router,
    apolloProvider,
    provide: {
      highlightWorker,
      targetBranch,
      originalBranch,
      resourceId,
      userId,
      explainCodeAvailable: parseBoolean(explainCodeAvailable),
      canDownloadCode: parseBoolean(canDownloadCode),
      hasRevsFile: parseBoolean(hasRevsFile),
      newWorkspacePath,
    },
    render(createElement) {
      return createElement(RepositoryApp, {
        props: {
          path: blobPath,
          projectPath,
          refType,
        },
      });
    },
  });
}
