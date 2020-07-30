import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import PackagesApp from './components/app.vue';
import Translate from '~/vue_shared/translate';
import createStore from './store';

Vue.use(Translate);

export default () => {
  const el = document.querySelector('#js-vue-packages-detail');
  const { package: packageJson, canDelete: canDeleteStr, oneColumnView, ...rest } = el.dataset;
  const packageEntity = JSON.parse(packageJson);
  const canDelete = canDeleteStr === 'true';

  const store = createStore({
    packageEntity,
    packageFiles: packageEntity.package_files,
    canDelete,
    oneColumnView: parseBoolean(oneColumnView),
    ...rest,
  });

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      PackagesApp,
    },
    store,
    render(createElement) {
      return createElement('packages-app');
    },
  });
};
