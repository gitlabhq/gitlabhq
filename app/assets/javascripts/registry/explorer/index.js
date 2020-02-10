import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import RegistryExplorer from './pages/index.vue';
import { createStore } from './stores';
import createRouter from './router';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-container-registry');

  if (!el) {
    return null;
  }

  const { endpoint } = el.dataset;

  const store = createStore();
  const router = createRouter(endpoint, store);
  store.dispatch('setInitialState', el.dataset);

  return new Vue({
    el,
    store,
    router,
    components: {
      RegistryExplorer,
    },
    render(createElement) {
      return createElement('registry-explorer');
    },
  });
};
