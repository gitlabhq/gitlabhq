import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import initWebIdeLink from '~/pages/projects/shared/web_ide_link';
import PerformancePlugin from '~/performance/vue_performance_plugin';
import createStore from '~/code_navigation/store';
import HighlightWorker from '~/vue_shared/components/source_viewer/workers/highlight_worker?worker';
import initFileTreeBrowser from '~/repository/file_tree_browser';

import RepositoryApp from './components/app.vue';
import RepositoryBreadcrumbs from './components/header_area/breadcrumbs.vue';
import ForkInfo from './components/fork_info.vue';
import LastCommit from './components/last_commit.vue';

import apolloProvider from './graphql';
import commitsQuery from './queries/commits.query.graphql';
import projectPathQuery from './queries/project_path.query.graphql';
import projectShortPathQuery from './queries/project_short_path.query.graphql';
import refsQuery from './queries/ref.query.graphql';
import createRouter from './router';
import { updateFormAction } from './utils/dom';
import { generateHistoryUrl } from './utils/url_utility';
import initHeaderApp from './init_header_app';

Vue.use(Vuex);
Vue.use(PerformancePlugin, {
  components: ['SimpleViewer', 'BlobContent'],
});

export default function setupVueRepositoryList() {
  const el = document.getElementById('js-tree-list');
  const { dataset } = el;
  const {
    projectPath,
    projectShortPath,
    ref,
    escapedRef,
    fullName,
    resourceId,
    userId,
    explainCodeAvailable,
    targetBranch,
    refType,
    hasRevsFile,
  } = dataset;
  const router = createRouter(projectPath, escapedRef, fullName);
  initFileTreeBrowser(router, { projectPath, ref, refType }, apolloProvider);

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: commitsQuery,
    data: {
      commits: [],
    },
  });

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: projectPathQuery,
    data: {
      projectPath,
    },
  });

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: projectShortPathQuery,
    data: {
      projectShortPath,
    },
  });

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: refsQuery,
    data: {
      ref,
      escapedRef,
    },
  });

  const initForkInfo = () => {
    const forkEl = document.getElementById('js-fork-info');
    if (!forkEl) {
      return null;
    }
    const {
      selectedBranch,
      sourceName,
      sourcePath,
      sourceDefaultBranch,
      createMrPath,
      viewMrPath,
      canSyncBranch,
      aheadComparePath,
      behindComparePath,
    } = forkEl.dataset;
    return new Vue({
      el: forkEl,
      name: 'ForkInfoRoot',
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

  const lastCommitEl = document.getElementById('js-last-commit');

  const initLastCommitApp = () =>
    new Vue({
      el: lastCommitEl,
      name: 'LastCommitRoot',
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

  initHeaderApp({ router });
  initLastCommitApp();
  initForkInfo();

  const breadcrumbEl = document.getElementById('js-repo-breadcrumb');

  if (breadcrumbEl) {
    const {
      canCollaborate,
      canEditTree,
      canPushCode,
      canPushToBranch,
      selectedBranch,
      newBranchPath,
      newTagPath,
      newBlobPath,
      forkNewBlobPath,
      forkNewDirectoryPath,
      forkUploadBlobPath,
      uploadPath,
      newDirPath,
    } = breadcrumbEl.dataset;

    router.afterEach(({ params: { path } }) => {
      updateFormAction('.js-create-dir-form', newDirPath, path);
    });

    // eslint-disable-next-line no-new
    new Vue({
      el: breadcrumbEl,
      name: 'RepositoryBreadcrumbsRoot',
      router,
      apolloProvider,
      render(h) {
        return h(RepositoryBreadcrumbs, {
          props: {
            currentPath: this.$route.params.path,
            refType: this.$route.query.ref_type,
            canCollaborate: parseBoolean(canCollaborate),
            canPushToBranch: parseBoolean(canPushToBranch),
            canEditTree: parseBoolean(canEditTree),
            canPushCode: parseBoolean(canPushCode),
            originalBranch: ref,
            selectedBranch,
            newBranchPath,
            newTagPath,
            newBlobPath,
            forkNewBlobPath,
            forkNewDirectoryPath,
            forkUploadBlobPath,
            uploadPath,
            newDirPath,
          },
        });
      },
    });
  }

  initWebIdeLink({ el: document.getElementById('js-tree-web-ide-link'), router });

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'RepositoryAppRoot',
    store: createStore(),
    router,
    apolloProvider,
    provide: {
      resourceId,
      userId,
      targetBranch,
      explainCodeAvailable: parseBoolean(explainCodeAvailable),
      highlightWorker: new HighlightWorker(),
      hasRevsFile: parseBoolean(hasRevsFile),
    },
    render(h) {
      return h(RepositoryApp);
    },
  });

  return { router, data: dataset, apolloProvider, projectPath };
}
