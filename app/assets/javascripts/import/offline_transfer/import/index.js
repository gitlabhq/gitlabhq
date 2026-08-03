import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import OfflineTransferImportApp from '~/import/offline_transfer/import/app.vue';

export const initOfflineTransferImport = () => {
  const el = document.getElementById('js-offline-transfer-import');

  if (!el) return null;

  return initVueApp({ el, name: 'OfflineTransferImportRoot', component: OfflineTransferImportApp });
};
