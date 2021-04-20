import Vue from 'vue';
import RunnerDetailsApp from './runner_details_app.vue';

export const initRunnerDetail = (selector = '#js-runner-detail') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const { runnerId } = el.dataset;

  return new Vue({
    el,
    render(h) {
      return h(RunnerDetailsApp, {
        props: {
          runnerId,
        },
      });
    },
  });
};
