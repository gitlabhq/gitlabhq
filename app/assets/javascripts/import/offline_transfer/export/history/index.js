import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import OfflineTransferExportHistoryApp from '~/import/offline_transfer/export/history/app.vue';

export const initOfflineTransferExportHistory = () => {
  const el = document.getElementById('js-offline-transfer-export-history');

  if (!el) return null;

  return initVueApp({
    el,
    name: 'OfflineTransferExportHistoryRoot',
    component: OfflineTransferExportHistoryApp,
  });
};
