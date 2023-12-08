import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import GlobalSearchSidebar from './components/app.vue';

Vue.use(Translate);

export const initSidebar = (store) => {
  const el = document.getElementById('js-search-sidebar');
  const hederEl = document.getElementById('super-sidebar-context-header');
  const headerText = hederEl.innerText;

  if (!el) return false;

  return new Vue({
    el,
    name: 'GlobalSearchSidebar',
    store,
    render(createElement) {
      return createElement(GlobalSearchSidebar, {
        props: {
          headerText,
        },
      });
    },
  });
};
