import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import ContributorsGraphs from './components/contributors.vue';
import { createStore } from './stores';

export default () => {
  const el = document.querySelector('.js-contributors-graph');

  if (!el) return null;

  const { projectGraphPath, projectBranch, defaultBranch, projectId, commitsPath } = el.dataset;
  const store = createStore(defaultBranch);

  return initVueApp({
    el,
    name: 'ContributorsGraphsRoot',
    store,
    component: ContributorsGraphs,
    props: {
      endpoint: projectGraphPath,
      branch: projectBranch,
      projectId,
      commitsPath,
    },
  });
};
