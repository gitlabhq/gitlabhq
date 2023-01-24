import Vue from 'vue';
import ContributorsGraphs from './components/contributors.vue';
import { createStore } from './stores';

export default () => {
  const el = document.querySelector('.js-contributors-graph');

  if (!el) return null;

  const { projectGraphPath, projectBranch, defaultBranch, projectId, commitsPath } = el.dataset;
  const store = createStore(defaultBranch);

  return new Vue({
    el,
    store,
    render(createElement) {
      return createElement(ContributorsGraphs, {
        props: {
          endpoint: projectGraphPath,
          branch: projectBranch,
          projectId,
          commitsPath,
        },
      });
    },
  });
};
