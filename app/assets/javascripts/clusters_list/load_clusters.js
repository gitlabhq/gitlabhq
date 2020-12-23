import Clusters from './components/clusters.vue';
import { createStore } from './store';

export default (Vue) => {
  const el = document.querySelector('#js-clusters-list-app');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    store: createStore(el.dataset),
    render(createElement) {
      return createElement(Clusters);
    },
  });
};
