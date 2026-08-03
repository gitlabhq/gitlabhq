import Vue from 'vue';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import Translate from '~/vue_shared/translate';
import GlobalSearchTopbar from './components/app.vue';

Vue.use(Translate);

export const initTopbar = (store) => {
  const el = document.getElementById('js-search-topbar');

  if (!el) {
    return false;
  }

  return initVueApp({ el, name: 'GlobalSearchTopbar', store, component: GlobalSearchTopbar });
};
