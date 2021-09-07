import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import HeaderSearchApp from './components/app.vue';

Vue.use(Translate);

export const initHeaderSearchApp = () => {
  const el = document.getElementById('js-header-search');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    render(createElement) {
      return createElement(HeaderSearchApp);
    },
  });
};
