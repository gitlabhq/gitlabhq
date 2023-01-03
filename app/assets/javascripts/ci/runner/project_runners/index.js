import Vue from 'vue';
import ProjectRunnersApp from './project_runners_app.vue';

export const initProjectRunners = (selector = '#js-project-runners') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const { projectFullPath } = el.dataset;

  return new Vue({
    el,
    render(h) {
      return h(ProjectRunnersApp, {
        props: {
          projectFullPath,
        },
      });
    },
  });
};
