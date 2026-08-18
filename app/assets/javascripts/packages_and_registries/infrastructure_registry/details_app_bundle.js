import Vue from 'vue';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { parseBoolean } from '~/lib/utils/common_utils';
import PackagesApp from '~/packages_and_registries/infrastructure_registry/details/components/app.vue';
import Translate from '~/vue_shared/translate';

Vue.use(Translate);

export default () => {
  const el = document.querySelector('#js-vue-packages-detail');
  const {
    package: packageJson,
    canDelete: canDeleteStr,
    gitlabHost,
    projectPath,
    projectName,
    projectListUrl,
    svgPath,
  } = el.dataset;
  const packageEntity = JSON.parse(packageJson);
  const canDelete = parseBoolean(canDeleteStr);

  return initVueApp({
    el,
    name: 'PackagesAppRoot',
    provide: {
      canDelete,
      gitlabHost,
      projectListUrl,
      projectName,
      projectPath,
      svgPath,
    },
    component: PackagesApp,
    props: {
      initialPackageEntity: packageEntity,
      initialPackageFiles: packageEntity.package_files,
    },
  });
};
