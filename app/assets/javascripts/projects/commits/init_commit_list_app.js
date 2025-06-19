import Vue from 'vue';
import CommitListApp from './components/commit_list_app.vue';

export default function initCommitListApp() {
  const commitListEl = document.getElementById('js-commit-list');

  if (!commitListEl) return;

  const { projectPath, currentPath } = commitListEl.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el: commitListEl,
    provide: {
      projectPath,
      currentPath,
    },
    render(h) {
      return h(CommitListApp, {});
    },
  });
}
