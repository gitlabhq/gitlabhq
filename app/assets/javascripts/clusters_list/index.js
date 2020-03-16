import Vue from 'vue';
import Clusters from './components/clusters.vue';
import { createStore } from './store';

export default () => {
  const entryPoint = document.querySelector('#js-clusters-list-app');

  if (!entryPoint) {
    return;
  }

  const { endpoint } = entryPoint.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el: '#js-clusters-list-app',
    store: createStore({ endpoint }),
    render(createElement) {
      return createElement(Clusters);
    },
  });
};
