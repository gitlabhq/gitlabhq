import { GlButton } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import { joinPaths, escapeFileUrl, visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import initWebIdeLink from '~/pages/projects/shared/web_ide_link';
import PerformancePlugin from '~/performance/vue_performance_plugin';
import createStore from '~/code_navigation/store';
import RefSelector from '~/ref/components/ref_selector.vue';
import HighlightWorker from '~/vue_shared/components/source_viewer/workers/highlight_worker?worker';
import CodeDropdown from '~/vue_shared/components/code_dropdown/code_dropdown.vue';
import App from './components/app.vue';
import Breadcrumbs from './components/breadcrumbs.vue';
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
            refType: this.$route.meta.refType || this.$route.query.ref_type,
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
            refType: this.$route.meta.refType || this.$route.query.ref_type,
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

  const initCodeDropdown = () => {
    const codeDropdownEl = document.getElementById('js-code-dropdown');

    if (!codeDropdownEl) return false;

    const {
      sshUrl,
      httpUrl,
      kerberosUrl,
      xcodeUrl,
      directoryDownloadLinks,
    } = codeDropdownEl.dataset;

    return new Vue({
      el: codeDropdownEl,
      router,
      render(createElement) {
        return createElement(CodeDropdown, {
          props: {
            sshUrl,
            httpUrl,
            kerberosUrl,
            xcodeUrl,
            currentPath: this.$route.params.path,
            directoryDownloadLinks: JSON.parse(directoryDownloadLinks),
          },
        });
      },
    });
  };

  initCodeDropdown();
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
            refType: this.$route.query.ref_type,
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
  // eslint-disable-next-line no-new
  new Vue({
    el: treeHistoryLinkEl,
    router,
    render(h) {
      const url = new URL(window.location.href);
      url.pathname = `${historyLink}/${
        this.$route.params.path ? escapeFileUrl(this.$route.params.path) : ''
      }`;
      url.searchParams.set('ref_type', this.$route.meta.refType || this.$route.query.ref_type);
      return h(
        GlButton,
        {
          attrs: {
            href: url.href,
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

  // eslint-disable-next-line no-new
  new Vue({
    el,
    store: createStore(),
    router,
    apolloProvider,
    provide: {
      resourceId,
      userId,
      explainCodeAvailable: parseBoolean(explainCodeAvailable),
      highlightWorker: new HighlightWorker(),
    },
    render(h) {
      return h(App);
    },
  });

  return { router, data: dataset, apolloProvider, projectPath };
}
