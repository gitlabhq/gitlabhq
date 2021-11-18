import Clusters from './components/clusters.vue';
import { createStore } from './store';

export default (Vue) => {
  const el = document.querySelector('#js-clusters-list-app');

  if (!el) {
    return null;
  }

  const { emptyStateHelpText, newClusterPath, clustersEmptyStateImage } = el.dataset;

  return new Vue({
    el,
    provide: {
      emptyStateHelpText,
      newClusterPath,
      clustersEmptyStateImage,
    },
    store: createStore(el.dataset),
    render(createElement) {
      return createElement(Clusters);
    },
  });
};
