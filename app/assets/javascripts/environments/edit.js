import Vue from 'vue';
import EditEnvironment from './components/edit_environment.vue';

export default (el) =>
  new Vue({
    el,
    provide: {
      projectEnvironmentsPath: el.dataset.projectEnvironmentsPath,
      updateEnvironmentPath: el.dataset.updateEnvironmentPath,
    },
    render(h) {
      return h(EditEnvironment, {
        props: {
          environment: JSON.parse(el.dataset.environment),
        },
      });
    },
  });
