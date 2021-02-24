import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Translate from '~/vue_shared/translate';
import ImportTable from './components/import_table.vue';
import { createApolloClient } from './graphql/client_factory';

Vue.use(Translate);
Vue.use(VueApollo);

export function mountImportGroupsApp(mountElement) {
  if (!mountElement) return undefined;

  const {
    statusPath,
    availableNamespacesPath,
    createBulkImportPath,
    jobsPath,
    sourceUrl,
    groupPathRegex,
  } = mountElement.dataset;
  const apolloProvider = new VueApollo({
    defaultClient: createApolloClient({
      sourceUrl,
      endpoints: {
        status: statusPath,
        availableNamespaces: availableNamespacesPath,
        createBulkImport: createBulkImportPath,
        jobs: jobsPath,
      },
    }),
  });

  return new Vue({
    el: mountElement,
    apolloProvider,
    render(createElement) {
      return createElement(ImportTable, {
        props: {
          sourceUrl,
          groupPathRegex: new RegExp(`^(${groupPathRegex})$`),
        },
      });
    },
  });
}
