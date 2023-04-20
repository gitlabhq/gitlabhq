import { GlButton } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import { joinPaths, escapeFileUrl, visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import initWebIdeLink from '~/pages/projects/shared/web_ide_link';
import PerformancePlugin from '~/performance/vue_performance_plugin';
import createStore from '~/code_navigation/store';
import RefSelector from '~/ref/components/ref_selector.vue';
import App from './components/app.vue';
import Breadcrumbs from './components/breadcrumbs.vue';
import DirectoryDownloadLinks from './components/directory_download_links.vue';
import ForkInfo from './components/fork_info.vue';
import LastCommit from './components/last_commit.vue';
import BlobControls from './components/blob_controls.vue';
import apolloProvider from './graphql';
import commitsQuery from './queries/commits.query.graphql';
import projectPathQuery from './queries/project_path.query.graphql';
import projectShortPathQuery from './queries/project_short_path.query.graphql';
import refsQuery from './queries/ref.query.graphql';
import createRouter from './router';
import { updateFormAction } from './utils/dom';
import { setTitle } from './utils/title';
import { generateRefDestinationPath } from './utils/ref_switcher_utils';

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
  } = dataset;
  const router = createRouter(projectPath, escapedRef);

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

  const initLastCommitApp = () =>
    new Vue({
      el: document.getElementById('js-last-commit'),
      router,
      apolloProvider,
      render(h) {
        return h(LastCommit, {
          props: {
            currentPath: this.$route.params.path,
          },
        });
      },
    });

  const initBlobControlsApp = () =>
    new Vue({
      el: document.getElementById('js-blob-controls'),
      router,
      apolloProvider,
      render(h) {
        return h(BlobControls, {
          props: {
            projectPath,
          },
        });
      },
    });

  const initRefSwitcher = () => {
    const refSwitcherEl = document.getElementById('js-tree-ref-switcher');

    if (!refSwitcherEl) return false;

    const { projectId, projectRootPath, refType } = refSwitcherEl.dataset;

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

  initLastCommitApp();
  initBlobControlsApp();
  initRefSwitcher();
  initForkInfo();

  router.afterEach(({ params: { path } }) => {
    setTitle(path, ref, fullName);
  });

  const breadcrumbEl = document.getElementById('js-repo-breadcrumb');

  if (breadcrumbEl) {
    const {
      canCollaborate,
      canEditTree,
      canPushCode,
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
      router,
      apolloProvider,
      render(h) {
        return h(Breadcrumbs, {
          props: {
            currentPath: this.$route.params.path,
            canCollaborate: parseBoolean(canCollaborate),
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

  const treeHistoryLinkEl = document.getElementById('js-tree-history-link');
  const { historyLink } = treeHistoryLinkEl.dataset;
  let { isProjectOverview } = treeHistoryLinkEl.dataset;

  const isProjectOverviewAfterEach = router.afterEach(() => {
    isProjectOverview = false;
    isProjectOverviewAfterEach();
  });

  // eslint-disable-next-line no-new
  new Vue({
    el: treeHistoryLinkEl,
    router,
    render(h) {
      if (parseBoolean(isProjectOverview) && !this.$route.params.path) return null;

      return h(
        GlButton,
        {
          attrs: {
            href: `${historyLink}/${
              this.$route.params.path ? escapeFileUrl(this.$route.params.path) : ''
            }`,
            // Ideally passing this class to `props` should work
            // But it doesn't work here. :(
            class: 'btn btn-default btn-md gl-button',
          },
        },
        [__('History')],
      );
    },
  });

  initWebIdeLink({ el: document.getElementById('js-tree-web-ide-link'), router });

  const directoryDownloadLinks = document.getElementById('js-directory-downloads');

  if (directoryDownloadLinks) {
    // eslint-disable-next-line no-new
    new Vue({
      el: directoryDownloadLinks,
      router,
      render(h) {
        const currentPath = this.$route.params.path || '/';

        if (currentPath !== '/') {
          return h(DirectoryDownloadLinks, {
            props: {
              currentPath: currentPath.replace(/^\//, ''),
              links: JSON.parse(directoryDownloadLinks.dataset.links),
            },
          });
        }

        return null;
      },
    });
  }

  // eslint-disable-next-line no-new
  new Vue({
    el,
    store: createStore(),
    router,
    apolloProvider,
    provide: { resourceId, userId, explainCodeAvailable: parseBoolean(explainCodeAvailable) },
    render(h) {
      return h(App);
    },
  });

  return { router, data: dataset, apolloProvider, projectPath };
}
