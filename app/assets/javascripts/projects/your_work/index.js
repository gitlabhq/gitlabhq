import Vue from 'vue';
import YourWorkProjectsApp from './components/app.vue';

export const initYourWorkProjects = () => {
  const el = document.getElementById('js-your-work-projects-app');

  if (!el) return false;

  return new Vue({
    el,
    name: 'YourWorkProjectsRoot',
    render(createElement) {
      return createElement(YourWorkProjectsApp);
    },
  });
};
