import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import Translate from '~/vue_shared/translate';
import PackagesApp from '../components/details/app.vue';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-vue-packages-detail-new');
  if (!el) {
    return null;
  }

  const { canDelete, ...datasetOptions } = el.dataset;
  return new Vue({
    el,
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
