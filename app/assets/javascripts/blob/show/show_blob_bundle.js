import { BlobViewer, initAuxiliaryViewer } from '~/blob/viewer/index';
import initBlob from '~/pages/projects/init_blob';
import { initWebIdeLink } from '~/pages/projects/shared/web_ide_link/init_web_ide_link';
import '~/sourcegraph/load';
import initAmbiguousRefModal from '~/vue_shared/components/ref/init_ambiguous_ref_modal';
import initRepositoryPage from '~/repository/init_repository_page';
import apolloProvider from '~/repository/graphql';
import { showAlertFromLocalStorage } from '~/lib/utils/local_storage_alert';
import initForkInfoApp from '~/repository/init_fork_info_app';
import initTableOfContentsApp from '~/blob/init_table_of_contents_app';
import initPerformancePlugin from '~/performance/init_performance_plugin';

export default function initBlobShow() {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  const performancePluginComponents = ['SourceViewer', 'Chunk'];
  const viewBlobEl = document.getElementById('js-view-blob-app');
  const webIdeLinkEl = document.getElementById('js-blob-web-ide-link');
  const codeNavEl = document.getElementById('js-code-navigation');

  // The expanded view renders code owners without the Vue blob app, so there is
  // no router on that path and callers get null.
  let router = null;

  initPerformancePlugin(performancePluginComponents);
  initAmbiguousRefModal();
  showAlertFromLocalStorage();

  if (viewBlobEl) {
    ({ router } = initRepositoryPage());
    initAuxiliaryViewer();
    initBlob();
  } else {
    new BlobViewer(); // eslint-disable-line no-new
    initBlob();
    initForkInfoApp();
  }

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

  return { router, apolloProvider };
}
