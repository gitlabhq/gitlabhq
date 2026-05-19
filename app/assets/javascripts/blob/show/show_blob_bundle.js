import { provideWebIdeLink } from 'ee_else_ce/pages/projects/shared/web_ide_link/provide_web_ide_link';
import { BlobViewer, initAuxiliaryViewer } from '~/blob/viewer/index';
import GpgBadges from '~/gpg_badges';
import initBlob from '~/pages/projects/init_blob';
import { initWebIdeLink } from '~/pages/projects/shared/web_ide_link/init_web_ide_link';
import '~/sourcegraph/load';
import HighlightWorker from '~/vue_shared/components/source_viewer/workers/highlight_worker?worker';
import initAmbiguousRefModal from '~/ref/init_ambiguous_ref_modal';
import { initFindFileShortcut } from '~/projects/behaviors';
import initHeaderApp from '~/repository/init_header_app';
import createRouter from '~/repository/router';
import initFileTreeBrowser from '~/repository/file_tree_browser';
import apolloProvider from '~/repository/graphql';
import projectPathQuery from '~/repository/queries/project_path.query.graphql';
import refsQuery from '~/repository/queries/ref.query.graphql';
import { showAlertFromLocalStorage } from '~/lib/utils/local_storage_alert';
import initLastCommitApp from '~/repository/init_last_commit_app';
import initRepositoryApp from '~/repository/init_repository_app';
import initForkInfoApp from '~/repository/init_fork_info_app';
import initTreeHistoryLinkApp from '~/repository/init_tree_history_link_app';
import initCommitPipelineStatus from '~/projects/tree/init_commit_pipeline_status';
import initTableOfContentsApp from '~/blob/init_table_of_contents_app';
import initPerformancePlugin from '~/performance/init_performance_plugin';

export default function initBlobShow() {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  const performancePluginComponents = ['SourceViewer', 'Chunk'];
  const viewBlobEl = document.querySelector('#js-view-blob-app');
  const webIdeLinkEl = document.getElementById('js-blob-web-ide-link');
  const codeNavEl = document.getElementById('js-code-navigation');

  initPerformancePlugin(performancePluginComponents);
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

    // Initialize Apollo cache with critical GraphQL queries
    // These must be set before calling init functions that depend on them
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

    const repositoryAppOptions = {
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
    };

    const router = createRouter(projectPath, originalBranch, fullName);

    initFileTreeBrowser(router, { projectPath, ref: originalBranch, refType });
    initLastCommitApp(router);
    initHeaderApp({ router, isBlobView: true });
    initRepositoryApp(router, repositoryAppOptions);

    initAuxiliaryViewer();
    initBlob();
  } else {
    new BlobViewer(); // eslint-disable-line no-new
    initBlob();
  }

  initForkInfoApp();
  initCommitPipelineStatus();
  initWebIdeLink({ el: webIdeLinkEl });

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
  GpgBadges.fetch();
}
