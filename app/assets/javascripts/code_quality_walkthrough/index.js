import Vue from 'vue';
import Step from './components/step.vue';

export default (el) =>
  new Vue({
    el,
    render(createElement) {
      return createElement(Step, {
        props: {
          step: el.dataset.step,
        },
      });
    },
  });
