import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import GlobalSearchSidebar from './components/app.vue';

Vue.use(Translate);

export const initSidebar = store => {
  const el = document.getElementById('js-search-sidebar');

  if (!el) return false;

  return new Vue({
    el,
    store,
    render(createElement) {
      return createElement(GlobalSearchSidebar);
    },
  });
};
