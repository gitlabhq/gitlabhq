import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import ClustersDeprecationAlert from './components/clusters_deprecation_alert.vue';

export default () => {
  const el = document.querySelector('.js-clusters-deprecation-alert');

  if (!el) {
    return false;
  }

  const { message } = el.dataset;

  return initVueApp({
    el,
    name: 'ClustersDeprecationAlertRoot',
    provide: {
      message,
    },
    component: ClustersDeprecationAlert,
  });
};
