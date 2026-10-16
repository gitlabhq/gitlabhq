import { parseBoolean } from '@gitlab/frontend-utils';
import HighlightWorker from '~/highlight_js/workers/highlight_worker?worker';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createStore from '~/code_navigation/store';
import initFileTreeBrowser from '~/repository/file_tree_browser';
import apolloProvider from './graphql';
import initHeaderApp from './init_header_app';
import initLastCommitApp from './init_last_commit_app';
import initForkInfoApp from './init_fork_info_app';
import RepositoryApp from './components/app.vue';
import projectPathQuery from './queries/project_path.query.graphql';
import projectShortPathQuery from './queries/project_short_path.query.graphql';
import refsQuery from './queries/ref.query.graphql';
import createRouter from './router';

export default function initRepositoryPage() {
  const el = document.getElementById('js-tree-list') || document.getElementById('js-view-blob-app');
  if (!el) return null;

  const { dataset } = el;
  const {
    projectPath,
    originalBranch,
    escapedRef,
    fullName,
    resourceId,
    explainCodeAvailable,
    refType,
    canDownloadCode,
    hasRevsFile,
  } = dataset;
  // The tree helper sends the raw ref as `ref`, the blob helper as `original_branch`.
  const ref = dataset.ref || originalBranch;
  // On blob pages only the header region carries the short path, until the
  // consolidated helper from
  // https://gitlab.com/gitlab-org/gitlab/-/work_items/630950 lands.
  const projectShortPath =
    dataset.projectShortPath ||
    document.getElementById('js-repository-blob-header-app')?.dataset?.projectShortPath;

  // The route patterns embed encoded variants of the base ref, so the base
  // must be the pre-encoded ref; a raw ref containing '#' or '%' double-encodes.
  const router = createRouter(projectPath, escapedRef, fullName);

  const { cache } = apolloProvider.clients.defaultClient;
  cache.writeQuery({ query: projectPathQuery, data: { projectPath } });
  if (projectShortPath) {
    cache.writeQuery({ query: projectShortPathQuery, data: { projectShortPath } });
  }
  cache.writeQuery({ query: refsQuery, data: { ref, escapedRef } });

  initFileTreeBrowser(router, { projectPath, ref, refType });
  initHeaderApp({ router });
  initLastCommitApp(router);
  initForkInfoApp();

  initVueApp({
    el,
    name: 'RepositoryAppRoot',
    store: createStore(),
    router,
    apolloProvider,
    provide: {
      resourceId,
      originalBranch: ref,
      explainCodeAvailable: parseBoolean(explainCodeAvailable),
      canDownloadCode: parseBoolean(canDownloadCode),
      hasRevsFile: parseBoolean(hasRevsFile),
      highlightWorker: new HighlightWorker(),
    },
    component: RepositoryApp,
  });

  return { router, data: dataset, apolloProvider, projectPath };
}
