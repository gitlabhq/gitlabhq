import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import GlobalSearchTopbar from './components/app.vue';

Vue.use(Translate);

export const initTopbar = (store) => {
  const el = document.getElementById('js-search-topbar');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    name: 'GlobalSearchTopbar',
    store,
    render(createElement) {
      return createElement(GlobalSearchTopbar);
    },
  });
};
