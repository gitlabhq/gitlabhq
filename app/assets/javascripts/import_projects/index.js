import Vue from 'vue';
import Translate from '../vue_shared/translate';
import ImportProjectsTable from './components/import_projects_table.vue';
import { parseBoolean } from '../lib/utils/common_utils';
import { queryToObject } from '../lib/utils/url_utility';
import createStore from './store';

Vue.use(Translate);

export function initStoreFromElement(element) {
  const {
    ciCdOnly,
    canSelectNamespace,
    provider,

    reposPath,
    jobsPath,
    importPath,
    namespacesPath,
    paginatable,
  } = element.dataset;

  const params = queryToObject(document.location.search);
  const page = parseInt(params.page ?? 1, 10);

  return createStore({
    initialState: {
      defaultTargetNamespace: gon.current_username,
      ciCdOnly: parseBoolean(ciCdOnly),
      canSelectNamespace: parseBoolean(canSelectNamespace),
      provider,
      pageInfo: {
        page,
      },
    },
    endpoints: {
      reposPath,
      jobsPath,
      importPath,
      namespacesPath,
    },
    hasPagination: parseBoolean(paginatable),
  });
}

export function initPropsFromElement(element) {
  return {
    providerTitle: element.dataset.providerTitle,
    filterable: parseBoolean(element.dataset.filterable),
    paginatable: parseBoolean(element.dataset.paginatable),
  };
}

export default function mountImportProjectsTable(mountElement) {
  if (!mountElement) return undefined;

  const store = initStoreFromElement(mountElement);
  const props = initPropsFromElement(mountElement);

  return new Vue({
    el: mountElement,
    store,
    render(createElement) {
      return createElement(ImportProjectsTable, { props });
    },
  });
}
