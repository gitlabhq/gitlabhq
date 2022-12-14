import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { parseBoolean } from '~/lib/utils/common_utils';
import Translate from '~/vue_shared/translate';
import createDefaultClient from '~/lib/graphql';
import ImportProjectsTable from './components/import_projects_table.vue';

import createStore from './store';

Vue.use(Translate);
Vue.use(VueApollo);

export function initStoreFromElement(element) {
  const {
    ciCdOnly,
    canSelectNamespace,
    provider,

    reposPath,
    jobsPath,
    importPath,
    defaultTargetNamespace,
    paginatable,
  } = element.dataset;

  return createStore({
    initialState: {
      defaultTargetNamespace,
      ciCdOnly: parseBoolean(ciCdOnly),
      canSelectNamespace: parseBoolean(canSelectNamespace),
      provider,
    },
    endpoints: {
      reposPath,
      jobsPath,
      importPath,
    },
    hasPagination: parseBoolean(paginatable),
  });
}

export function initPropsFromElement(element) {
  return {
    providerTitle: element.dataset.providerTitle,
    filterable: parseBoolean(element.dataset.filterable),
    paginatable: parseBoolean(element.dataset.paginatable),
    optionalStages: JSON.parse(element.dataset.optionalStages),
  };
}

const defaultClient = createDefaultClient();

const apolloProvider = new VueApollo({
  defaultClient,
});

export default function mountImportProjectsTable(mountElement) {
  if (!mountElement) return undefined;

  const store = initStoreFromElement(mountElement);
  const props = initPropsFromElement(mountElement);

  return new Vue({
    el: mountElement,
    store,
    apolloProvider,
    render(createElement) {
      return createElement(ImportProjectsTable, { props });
    },
  });
}
