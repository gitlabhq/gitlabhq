import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { parseBoolean } from '~/lib/utils/common_utils';
import apolloProvider from '~/repository/graphql';
import RepositoryApp from '~/repository/components/app.vue';
import createStore from '~/code_navigation/store';

export default function initRepositoryApp(router, options = {}) {
  const viewBlobEl = document.querySelector('#js-view-blob-app');
  const {
    blobPath,
    projectPath,
    refType,
    originalBranch,
    resourceId,
    explainCodeAvailable,
    canDownloadCode,
    hasRevsFile,
    highlightWorker,
  } = options;

  if (!viewBlobEl || !blobPath || !projectPath || !highlightWorker) return null;

  return initVueApp({
    el: viewBlobEl,
    name: 'RepositoryAppRoot',
    store: createStore(),
    router,
    apolloProvider,
    provide: {
      highlightWorker,
      originalBranch,
      resourceId,
      explainCodeAvailable: parseBoolean(explainCodeAvailable),
      canDownloadCode: parseBoolean(canDownloadCode),
      hasRevsFile: parseBoolean(hasRevsFile),
    },
    component: RepositoryApp,
    props: {
      projectPath,
      refType,
    },
  });
}
