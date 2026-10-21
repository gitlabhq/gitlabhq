import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { pinia } from '~/pinia/instance';
import ContributorsGraphs from './components/contributors.vue';

export default () => {
  const el = document.querySelector('.js-contributors-graph');

  if (!el) return null;

  const { projectGraphPath, projectBranch, projectId, commitsPath } = el.dataset;

  return initVueApp({
    el,
    name: 'ContributorsGraphsRoot',
    pinia,
    component: ContributorsGraphs,
    props: {
      endpoint: projectGraphPath,
      branch: projectBranch,
      projectId,
      commitsPath,
    },
  });
};
