import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import PackagesApp from './components/app.vue';
import createStore from './store';

Vue.use(Translate);

export default () => {
  const el = document.querySelector('#js-vue-packages-detail');
  const { package: packageJson, canDelete: canDeleteStr, ...rest } = el.dataset;
  const packageEntity = JSON.parse(packageJson);
  const canDelete = canDeleteStr === 'true';

  const store = createStore({
    packageEntity,
    packageFiles: packageEntity.package_files,
    canDelete,
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
