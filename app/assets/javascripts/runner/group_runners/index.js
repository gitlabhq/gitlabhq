import Vue from 'vue';
import GroupRunnersApp from './group_runners_app.vue';

export const initGroupRunners = (selector = '#js-group-runners') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    render(h) {
      return h(GroupRunnersApp);
    },
  });
};
