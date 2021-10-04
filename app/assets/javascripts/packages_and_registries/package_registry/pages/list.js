import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import { apolloProvider } from '~/packages_and_registries/package_registry/graphql/index';
import PackagesListApp from '../components/list/app.vue';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-vue-packages-list');

  const isGroupPage = el.dataset.pageType === 'groups';

  return new Vue({
    el,
    apolloProvider,
    provide: {
      ...el.dataset,
      isGroupPage,
    },
    render(createElement) {
      return createElement(PackagesListApp);
    },
  });
};
