import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlButton } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { provideWebIdeLink } from 'ee_else_ce/pages/projects/shared/web_ide_link/provide_web_ide_link';
import TableOfContents from '~/blob/components/table_contents.vue';
import { BlobViewer, initAuxiliaryViewer } from '~/blob/viewer/index';
import { __ } from '~/locale';
import GpgBadges from '~/gpg_badges';
import createDefaultClient from '~/lib/graphql';
import initBlob from '~/pages/projects/init_blob';
import ForkInfo from '~/repository/components/fork_info.vue';
import initWebIdeLink from '~/pages/projects/shared/web_ide_link';
import CommitPipelineStatus from '~/projects/tree/components/commit_pipeline_status.vue';
import App from '~/repository/components/app.vue';
import '~/sourcegraph/load';
import createStore from '~/code_navigation/store';
import { generateHistoryUrl } from '~/repository/utils/url_utility';
import { parseBoolean } from '~/lib/utils/common_utils';
import HighlightWorker from '~/vue_shared/components/source_viewer/workers/highlight_worker?worker';
import initAmbiguousRefModal from '~/ref/init_ambiguous_ref_modal';
import { HISTORY_BUTTON_CLICK } from '~/tracking/constants';
import { initFindFileShortcut } from '~/projects/behaviors';
import initHeaderApp from '~/repository/init_header_app';
import createRouter from '~/repository/router';
import initFileTreeBrowser from '~/repository/file_tree_browser';
import LastCommit from '~/repository/components/last_commit.vue';
import projectPathQuery from '~/repository/queries/project_path.query.graphql';
import refsQuery from '~/repository/queries/ref.query.graphql';
import { showAlertFromLocalStorage } from '~/lib/utils/local_storage_alert';

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

const initLastCommitApp = (router) => {
  const lastCommitEl = document.getElementById('js-last-commit');
  if (!lastCommitEl) return null;

  return new Vue({
    el: lastCommitEl,
    router,
    apolloProvider,
    render(h) {
      const historyUrl = generateHistoryUrl(
        lastCommitEl.dataset.historyLink,
        this.$route.params.path,
        this.$route.meta.refType || this.$route.query.ref_type,
      );
      return h(LastCommit, {
        props: {
          currentPath: this.$route.params.path,
          refType: this.$route.meta.refType || this.$route.query.ref_type,
          historyUrl: historyUrl.href,
        },
      });
    },
  });
};

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
  initLastCommitApp(router);

  initHeaderApp({ router, isBlobView: true });

  // eslint-disable-next-line no-new
  new Vue({
    el: viewBlobEl,
    store: createStore(),
    router,
    apolloProvider,
    provide: {
      highlightWorker: new HighlightWorker(),
      targetBranch,
      originalBranch,
      resourceId,
      userId,
      explainCodeAvailable: parseBoolean(explainCodeAvailable),
      canDownloadCode: parseBoolean(canDownloadCode),
      hasRevsFile: parseBoolean(hasRevsFile),
      ...provideWebIdeLink(dataset),
    },
    render(createElement) {
      return createElement(App, {
        props: {
          path: blobPath,
          projectPath,
          refType,
        },
      });
    },
  });

  initAuxiliaryViewer();
  initBlob();
} else {
  new BlobViewer(); // eslint-disable-line no-new
  initBlob();
}

const initForkInfo = () => {
  const forkEl = document.getElementById('js-fork-info');
  if (!forkEl) {
    return null;
  }
  const {
    projectPath,
    selectedBranch,
    sourceName,
    sourcePath,
    sourceDefaultBranch,
    canSyncBranch,
    aheadComparePath,
    behindComparePath,
    createMrPath,
    viewMrPath,
  } = forkEl.dataset;
  return new Vue({
    el: forkEl,
    apolloProvider,
    render(h) {
      return h(ForkInfo, {
        props: {
          canSyncBranch: parseBoolean(canSyncBranch),
          projectPath,
          selectedBranch,
          sourceName,
          sourcePath,
          sourceDefaultBranch,
          aheadComparePath,
          behindComparePath,
          createMrPath,
          viewMrPath,
        },
      });
    },
  });
};

initForkInfo();

const commitPipelineStatusEl = document.querySelector('.js-commit-pipeline-status');

if (commitPipelineStatusEl) {
  // eslint-disable-next-line no-new
  new Vue({
    el: commitPipelineStatusEl,
    components: {
      CommitPipelineStatus,
    },
    render(createElement) {
      return createElement('commit-pipeline-status', {
        props: {
          endpoint: commitPipelineStatusEl.dataset.endpoint,
        },
      });
    },
  });
}

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

const tableContentsEl = document.querySelector('.js-table-contents');

if (tableContentsEl) {
  // eslint-disable-next-line no-new
  new Vue({
    el: tableContentsEl,
    render(h) {
      return h(TableOfContents);
    },
  });
}

const initTreeHistoryLinkApp = (el) => {
  const { historyLink } = el.dataset;
  // eslint-disable-next-line no-new
  new Vue({
    el,
    router: new VueRouter({ mode: 'history' }),
    render(h) {
      const url = generateHistoryUrl(
        historyLink,
        this.$route.params.path,
        this.$route.meta.refType || this.$route.query.ref_type,
      );
      return h(
        GlButton,
        {
          attrs: {
            href: url.href,
            'data-event-tracking': HISTORY_BUTTON_CLICK,
          },
        },
        [__('History')],
      );
    },
  });
};

const treeHistoryLinkEl = document.getElementById('js-commit-history-link');

if (treeHistoryLinkEl) {
  initTreeHistoryLinkApp(treeHistoryLinkEl);
}
