import Vue from 'vue';
import OfflineTransferExportApp from '~/import/offline_transfer/export/app.vue';

export const initOfflineTransferExport = () => {
  const el = document.getElementById('js-offline-transfer-export');

  if (!el) return null;

  return new Vue({
    el,
    name: 'OfflineTransferExportRoot',
    render(createElement) {
      return createElement(OfflineTransferExportApp, {});
    },
  });
};
