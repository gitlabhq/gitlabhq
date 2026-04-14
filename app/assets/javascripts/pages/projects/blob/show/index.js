import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { provideWebIdeLink } from 'ee_else_ce/pages/projects/shared/web_ide_link/provide_web_ide_link';
import { BlobViewer, initAuxiliaryViewer } from '~/blob/viewer/index';
import GpgBadges from '~/gpg_badges';
import createDefaultClient from '~/lib/graphql';
import initBlob from '~/pages/projects/init_blob';
import initWebIdeLink from '~/pages/projects/shared/web_ide_link';
import '~/sourcegraph/load';
import HighlightWorker from '~/vue_shared/components/source_viewer/workers/highlight_worker?worker';
import initAmbiguousRefModal from '~/ref/init_ambiguous_ref_modal';
import { initFindFileShortcut } from '~/projects/behaviors';
import initHeaderApp from '~/repository/init_header_app';
import createRouter from '~/repository/router';
import initFileTreeBrowser from '~/repository/file_tree_browser';
import projectPathQuery from '~/repository/queries/project_path.query.graphql';
import refsQuery from '~/repository/queries/ref.query.graphql';
import { showAlertFromLocalStorage } from '~/lib/utils/local_storage_alert';
import initLastCommitApp from '~/repository/init_last_commit_app';
import initRepositoryApp from '~/repository/init_repository_app';
import initForkInfoApp from '~/repository/init_fork_info_app';
import initTreeHistoryLinkApp from '~/repository/init_tree_history_link_app';
import initCommitPipelineStatus from '~/projects/tree/init_commit_pipeline_status';
import initTableOfContentsApp from '~/blob/init_table_of_contents_app';

import PerformancePlugin from '~/performance/vue_performance_plugin';

Vue.use(Vuex);
Vue.use(VueApollo);
Vue.use(VueRouter);

Vue.use(PerformancePlugin, {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  components: ['SourceViewer', 'Chunk'],
});

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

const viewBlobEl = document.querySelector('#js-view-blob-app');

initAmbiguousRefModal();
initFindFileShortcut();
showAlertFromLocalStorage();

if (viewBlobEl) {
  const {
    blobPath,
    projectPath,
    targetBranch,
    originalBranch,
    resourceId,
    userId,
    explainCodeAvailable,
    refType,
    escapedRef,
    canDownloadCode,
    fullName,
    hasRevsFile,
    ...dataset
  } = viewBlobEl.dataset;

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: projectPathQuery,
    data: {
      projectPath,
    },
  });

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: refsQuery,
    data: { ref: originalBranch, escapedRef },
  });

  const router = createRouter(projectPath, originalBranch, fullName);
  initFileTreeBrowser(router, { projectPath, ref: originalBranch, refType }, apolloProvider);
  initLastCommitApp(router, apolloProvider);

  initHeaderApp({ router, isBlobView: true });

  initRepositoryApp(router, apolloProvider, {
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
    highlightWorker: new HighlightWorker(),
    webIdeLinkData: provideWebIdeLink(dataset),
  });

  initAuxiliaryViewer();
  initBlob();
} else {
  new BlobViewer(); // eslint-disable-line no-new
  initBlob();
}

initForkInfoApp(apolloProvider);

initCommitPipelineStatus();

initWebIdeLink({ el: document.getElementById('js-blob-web-ide-link') });

GpgBadges.fetch();

const codeNavEl = document.getElementById('js-code-navigation');

if (codeNavEl && !viewBlobEl) {
  const { codeNavigationPath, blobPath, definitionPathPrefix } = codeNavEl.dataset;

  // eslint-disable-next-line promise/catch-or-return
  import('~/code_navigation').then((m) =>
    m.default({
      blobs: [{ path: blobPath, codeNavigationPath }],
      definitionPathPrefix,
    }),
  );
}

initTableOfContentsApp();

initTreeHistoryLinkApp();
