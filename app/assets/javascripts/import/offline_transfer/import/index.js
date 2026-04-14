import Vue from 'vue';
import OfflineTransferImportApp from '~/import/offline_transfer/import/app.vue';

export const initOfflineTransferImport = () => {
  const el = document.getElementById('js-offline-transfer-import');

  if (!el) return null;

  return new Vue({
    el,
    name: 'OfflineTransferImportRoot',
    render(createElement) {
      return createElement(OfflineTransferImportApp, {});
    },
  });
};
