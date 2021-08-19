import Vue from 'vue';
import NewEnvironment from './components/new_environment.vue';

export default (el) =>
  new Vue({
    el,
    provide: { projectEnvironmentsPath: el.dataset.projectEnvironmentsPath },
    render(h) {
      return h(NewEnvironment);
    },
  });
