import Vue from 'vue';
import NewProjectCreationApp from './components/app.vue';

export default function initNewProjectCreation(el, props) {
  const { pushToCreateProjectCommand, workingWithProjectsHelpPath } = el.dataset;

  return new Vue({
    el,
    components: {
      NewProjectCreationApp,
    },
    provide: {
      workingWithProjectsHelpPath,
      pushToCreateProjectCommand,
    },
    render(h) {
      return h(NewProjectCreationApp, { props });
    },
  });
}
