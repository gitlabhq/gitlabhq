import Vue from 'vue';
import ClustersDeprecationAlert from './components/clusters_deprecation_alert.vue';

export default () => {
  const el = document.querySelector('.js-clusters-deprecation-alert');

  if (!el) {
    return false;
  }

  const { message } = el.dataset;

  return new Vue({
    el,
    name: 'ClustersDeprecationAlertRoot',
    provide: {
      message,
    },
    render: (createElement) => createElement(ClustersDeprecationAlert),
  });
};
