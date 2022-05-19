import Vue from 'vue';
import NewCluster from './components/new_cluster.vue';

export default () => {
  const el = document.querySelector('#js-cluster-new');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    render(createElement) {
      return createElement(NewCluster);
    },
  });
};
