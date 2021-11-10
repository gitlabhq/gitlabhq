import Vue from 'vue';
import DeployKeysTable from './components/table.vue';

export const initAdminDeployKeysTable = () => {
  const el = document.getElementById('js-admin-deploy-keys-table');

  if (!el) return false;

  const { editPath, deletePath, createPath, emptyStateSvgPath } = el.dataset;

  return new Vue({
    el,
    provide: {
      editPath,
      deletePath,
      createPath,
      emptyStateSvgPath,
    },
    render(createElement) {
      return createElement(DeployKeysTable);
    },
  });
};
