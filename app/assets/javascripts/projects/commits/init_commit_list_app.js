import Vue from 'vue';
import CommitListApp from './components/commit_list_app.vue';
import apolloProvider from './graphql';

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
    path,
  } = commitListEl.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el: commitListEl,
    provide: {
      projectFullPath,
      projectRootPath,
      projectPath,
      projectId,
      escapedRef,
      refType,
      rootRef,
      path,
    },
    apolloProvider,
    render(h) {
      return h(CommitListApp, {});
    },
  });
}
