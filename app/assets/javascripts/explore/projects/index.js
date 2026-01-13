import Vue from 'vue';
import ExploreProjectsApp from '~/explore/projects/components/app.vue';

export const initExploreProjects = () => {
  const el = document.getElementById('js-explore-projects');

  if (!el) return null;

  return new Vue({
    el,
    name: 'ExploreProjectsRoot',
    render(createElement) {
      return createElement(ExploreProjectsApp, {});
    },
  });
};
