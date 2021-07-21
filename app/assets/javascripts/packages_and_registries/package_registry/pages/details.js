import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import PackagesApp from '~/packages_and_registries/package_registry/components/details/app.vue';
import { apolloProvider } from '~/packages_and_registries/package_registry/graphql/index';
import Translate from '~/vue_shared/translate';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-vue-packages-detail-new');
  if (!el) {
    return null;
  }

  const { canDelete, ...datasetOptions } = el.dataset;
  return new Vue({
    el,
    apolloProvider,
    provide: {
      canDelete: parseBoolean(canDelete),
      titleComponent: 'PackageTitle',
      ...datasetOptions,
    },
    render(createElement) {
      return createElement(PackagesApp);
    },
  });
};
