import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import Translate from '~/vue_shared/translate';
import ImportTable from './components/import_table.vue';
import { createApolloClient } from './graphql/client_factory';

Vue.use(Translate);
Vue.use(VueApollo);

export function mountImportGroupsApp(mountElement) {
  if (!mountElement) return undefined;

  const {
    statusPath,
    createBulkImportPath,
    jobsPath,
    historyPath,
    historyShowPath,
    defaultTargetNamespace,
    sourceUrl,
    groupPathRegex,
    importGroupPath,
  } = mountElement.dataset;
  const apolloProvider = new VueApollo({
    defaultClient: createApolloClient({
      sourceUrl,
      endpoints: {
        status: statusPath,
        createBulkImport: createBulkImportPath,
      },
    }),
  });

  return initVueApp({
    el: mountElement,
    name: 'ImportGroupsRoot',
    apolloProvider,
    component: ImportTable,
    props: {
      sourceUrl,
      jobsPath,
      groupPathRegex: new RegExp(`^(${groupPathRegex})$`),
      historyPath,
      historyShowPath,
      defaultTargetNamespace: parseInt(defaultTargetNamespace, 10) || null,
      importGroupPath,
    },
  });
}
