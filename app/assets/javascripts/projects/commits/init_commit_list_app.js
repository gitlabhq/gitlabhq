import Vue from 'vue';
import CommitListApp from './components/commit_list_app.vue';
import apolloProvider from './graphql';

export default function initCommitListApp() {
  const commitListEl = document.getElementById('js-commit-list');

  if (!commitListEl) return;

  const { projectFullPath } = commitListEl.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el: commitListEl,
    provide: {
      projectFullPath,
    },
    apolloProvider,
    render(h) {
      return h(CommitListApp, {});
    },
  });
}
