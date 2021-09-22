import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import PackagesListApp from '../components/list/app.vue';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-vue-packages-list');

  return new Vue({
    el,
    provide: {
      ...el.dataset,
    },
    render(createElement) {
      return createElement(PackagesListApp);
    },
  });
};
