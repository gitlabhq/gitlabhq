import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import OfflineTransferExportApp from '~/import/offline_transfer/export/app.vue';

Vue.use(VueApollo);

export const initOfflineTransferExport = () => {
  const el = document.getElementById('js-offline-transfer-export');

  if (!el) return null;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    name: 'OfflineTransferExportRoot',
    apolloProvider,
    render(createElement) {
      return createElement(OfflineTransferExportApp, {});
    },
  });
};
