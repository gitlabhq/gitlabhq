import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import DeployKeysTable from './components/table.vue';

export const initAdminDeployKeysTable = () => {
  const el = document.getElementById('js-admin-deploy-keys-table');

  if (!el) return false;

  return initVueApp({
    el,
    name: 'DeployKeysTableRoot',
    component: DeployKeysTable,
  });
};
