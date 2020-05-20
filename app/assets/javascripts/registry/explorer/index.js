import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import Translate from '~/vue_shared/translate';
import RegistryExplorer from './pages/index.vue';
import RegistryBreadcrumb from './components/registry_breadcrumb.vue';
import { createStore } from './stores';
import createRouter from './router';

Vue.use(Translate);
Vue.use(GlToast);

export default () => {
  const el = document.getElementById('js-container-registry');

  if (!el) {
    return null;
  }

  const { endpoint } = el.dataset;

  const store = createStore();
  const router = createRouter(endpoint);
  store.dispatch('setInitialState', el.dataset);

  const attachMainComponent = () =>
    new Vue({
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

  const attachBreadcrumb = () => {
    const breadCrumbEl = document.querySelector('nav .js-breadcrumbs-list');
    const crumbs = [...document.querySelectorAll('.js-breadcrumbs-list li')];
    return new Vue({
      el: breadCrumbEl,
      store,
      router,
      components: {
        RegistryBreadcrumb,
      },
      render(createElement) {
        return createElement('registry-breadcrumb', {
          class: breadCrumbEl.className,
          props: {
            crumbs,
          },
        });
      },
    });
  };

  return { attachBreadcrumb, attachMainComponent };
};
