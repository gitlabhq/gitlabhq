import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import { apolloProvider } from '~/packages_and_registries/package_registry/graphql/index';
import PackageRegistry from '~/packages_and_registries/package_registry/pages/index.vue';
import createRouter from './router';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-vue-packages-list');
  const { endpoint, resourceId, fullPath, pageType, emptyListIllustration } = el.dataset;
  const router = createRouter(endpoint);

  const isGroupPage = pageType === 'groups';

  return new Vue({
    el,
    router,
    apolloProvider,
    provide: {
      resourceId,
      fullPath,
      emptyListIllustration,
      isGroupPage,
    },
    render(createElement) {
      return createElement(PackageRegistry);
    },
  });
};
