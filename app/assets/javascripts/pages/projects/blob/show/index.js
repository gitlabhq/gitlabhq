import Vue from 'vue';
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import TableOfContents from '~/blob/components/table_contents.vue';
import PipelineTourSuccessModal from '~/blob/pipeline_tour_success_modal.vue';
import { BlobViewer, initAuxiliaryViewer } from '~/blob/viewer/index';
import GpgBadges from '~/gpg_badges';
import createDefaultClient from '~/lib/graphql';
import initBlob from '~/pages/projects/init_blob';
import ForkInfo from '~/repository/components/fork_info.vue';
import initWebIdeLink from '~/pages/projects/shared/web_ide_link';
import CommitPipelineStatus from '~/projects/tree/components/commit_pipeline_status_component.vue';
import BlobContentViewer from '~/repository/components/blob_content_viewer.vue';
import '~/sourcegraph/load';
import createStore from '~/code_navigation/store';
import { generateRefDestinationPath } from '~/repository/utils/ref_switcher_utils';
import RefSelector from '~/ref/components/ref_selector.vue';
import { joinPaths, visitUrl } from '~/lib/utils/url_utility';
import { parseBoolean } from '~/lib/utils/common_utils';

Vue.use(Vuex);
Vue.use(VueApollo);
Vue.use(VueRouter);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

const router = new VueRouter({ mode: 'history' });

const viewBlobEl = document.querySelector('#js-view-blob-app');

const initRefSwitcher = () => {
  const refSwitcherEl = document.getElementById('js-tree-ref-switcher');

  if (!refSwitcherEl) return false;

  const { projectId, projectRootPath, ref, refType } = refSwitcherEl.dataset;

  return new Vue({
    el: refSwitcherEl,
    render(createElement) {
      return createElement(RefSelector, {
        props: {
          projectId,
          value: refType ? joinPaths('refs', refType, ref) : ref,
          useSymbolicRefNames: true,
          queryParams: { sort: 'updated_desc' },
        },
        on: {
          input(selectedRef) {
            visitUrl(generateRefDestinationPath(projectRootPath, ref, selectedRef));
          },
        },
      });
    },
  });
};

initRefSwitcher();

if (viewBlobEl) {
  const {
    blobPath,
    projectPath,
    targetBranch,
    originalBranch,
    resourceId,
    userId,
    explainCodeAvailable,
  } = viewBlobEl.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el: viewBlobEl,
    store: createStore(),
    router,
    apolloProvider,
    provide: {
      targetBranch,
      originalBranch,
      resourceId,
      userId,
      explainCodeAvailable: parseBoolean(explainCodeAvailable),
    },
    render(createElement) {
      return createElement(BlobContentViewer, {
        props: {
          path: blobPath,
          projectPath,
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

const CommitPipelineStatusEl = document.querySelector('.js-commit-pipeline-status');
const statusLink = document.querySelector('.commit-actions .ci-status-link');
if (statusLink) {
  statusLink.remove();
  // eslint-disable-next-line no-new
  new Vue({
    el: CommitPipelineStatusEl,
    components: {
      CommitPipelineStatus,
    },
    render(createElement) {
      return createElement('commit-pipeline-status', {
        props: {
          endpoint: CommitPipelineStatusEl.dataset.endpoint,
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

const successPipelineEl = document.querySelector('.js-success-pipeline-modal');

if (successPipelineEl) {
  // eslint-disable-next-line no-new
  new Vue({
    el: successPipelineEl,
    render(createElement) {
      return createElement(PipelineTourSuccessModal, {
        props: {
          ...successPipelineEl.dataset,
        },
      });
    },
  });
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
