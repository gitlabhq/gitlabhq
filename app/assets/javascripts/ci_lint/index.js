import Vue from 'vue';
import CILint from './components/ci_lint.vue';

export default (containerId = '#js-ci-lint') => {
  const containerEl = document.querySelector(containerId);
  const { endpoint } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    render(createElement) {
      return createElement(CILint, {
        props: {
          endpoint,
        },
      });
    },
  });
};
