import Vue from 'vue';
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

  // eslint-disable-next-line no-new
  new Vue({
    el: commitListEl,
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
    render(h) {
      return h(CommitListApp, {});
    },
  });
}
