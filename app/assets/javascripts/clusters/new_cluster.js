import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import NewCluster from './components/new_cluster.vue';

export default () => {
  const el = document.querySelector('#js-cluster-new');

  if (!el) {
    return null;
  }

  return initVueApp({ el, name: 'NewClusterRoot', component: NewCluster });
};
