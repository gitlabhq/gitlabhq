import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import GlobalSearchSidebar from './components/app.vue';

Vue.use(Translate);

export const sidebarInitState = () => {
  const el = document.getElementById('js-search-sidebar');
  if (!el) return {};

  const { navigationJson } = el.dataset;
  const navigationJsonParsed = JSON.parse(navigationJson);
  return { navigationJsonParsed };
};

export const initSidebar = (store) => {
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
