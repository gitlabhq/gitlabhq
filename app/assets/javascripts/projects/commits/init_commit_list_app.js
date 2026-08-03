import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import CommitListApp from './components/commit_list_app.vue';
import apolloProvider from './graphql';
import { createRouter } from './router';

export default function initCommitListApp() {
  const commitListEl = document.getElementById('js-commit-list');

  if (!commitListEl) return;

  const {
    projectFullPath,
    projectRootPath,
    projectPath,
    projectId,
    escapedRef,
    refType,
    rootRef,
    browseFilesPath,
    commitsFeedPath,
    basePath,
  } = commitListEl.dataset;

  initVueApp({
    el: commitListEl,
    name: 'CommitListAppRoot',
    router: createRouter(basePath, escapedRef),
    provide: {
      projectFullPath,
      projectRootPath,
      projectPath,
      projectId,
      escapedRef,
      refType,
      rootRef,
      browseFilesPath,
      commitsFeedPath,
    },
    apolloProvider,
    component: CommitListApp,
  });
}
