import Vue from 'vue';
import NewCluster from './components/new_cluster.vue';
import { createStore } from './stores/new_cluster';

export default () => {
  const entryPoint = document.querySelector('#js-cluster-new');

  if (!entryPoint) {
    return null;
  }

  return new Vue({
    el: '#js-cluster-new',
    store: createStore(entryPoint.dataset),
    render(createElement) {
      return createElement(NewCluster);
    },
  });
};
