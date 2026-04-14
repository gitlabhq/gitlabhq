import Vue from 'vue';
import OfflineTransferApp from '~/import/offline_transfer/app.vue';

export const initOfflineTransfer = () => {
  const el = document.getElementById('js-offline-transfer');

  if (!el) return null;

  return new Vue({
    el,
    name: 'OfflineTransferRoot',
    render(createElement) {
      return createElement(OfflineTransferApp, {});
    },
  });
};
