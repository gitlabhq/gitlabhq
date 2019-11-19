import Vue from 'vue';
import ContributorsGraphs from './components/contributors.vue';
import store from './stores';

export default () => {
  const el = document.querySelector('.js-contributors-graph');

  if (!el) return null;

  return new Vue({
    el,
    store,

    render(createElement) {
      return createElement(ContributorsGraphs, {
        props: {
          endpoint: el.dataset.projectGraphPath,
          branch: el.dataset.projectBranch,
        },
      });
    },
  });
};
