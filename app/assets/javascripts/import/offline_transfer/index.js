import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import OfflineTransferApp from '~/import/offline_transfer/app.vue';

export const initOfflineTransfer = () => {
  const el = document.getElementById('js-offline-transfer');

  if (!el) return null;

  const { exportPath, importPath } = el.dataset;

  return initVueApp({
    el,
    name: 'OfflineTransferRoot',
    component: OfflineTransferApp,
    props: {
      exportPath,
      importPath,
    },
  });
};
