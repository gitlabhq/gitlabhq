import Vue from 'vue';
import DeployKeysTable from './components/table.vue';

export const initAdminDeployKeysTable = () => {
  const el = document.getElementById('js-admin-deploy-keys-table');

  if (!el) return false;

  return new Vue({
    el,
    name: 'DeployKeysTableRoot',
    render(createElement) {
      return createElement(DeployKeysTable);
    },
  });
};
