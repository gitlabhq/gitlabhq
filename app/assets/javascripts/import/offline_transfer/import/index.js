import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import OfflineTransferImportApp from '~/import/offline_transfer/import/app.vue';

Vue.use(VueApollo);

export const initOfflineTransferImport = () => {
  const el = document.getElementById('js-offline-transfer-import');

  if (!el) return null;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return initVueApp({
    el,
    name: 'OfflineTransferImportRoot',
    apolloProvider,
    component: OfflineTransferImportApp,
  });
};
