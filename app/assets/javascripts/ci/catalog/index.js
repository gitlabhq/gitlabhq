import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { cacheConfig, resolvers } from '~/ci/catalog/graphql/settings';
import typeDefs from '~/ci/catalog/graphql/typedefs.graphql';

import GlobalCatalog from './global_catalog.vue';
import CiResourcesPage from './components/pages/ci_resources_page.vue';
import { createRouter } from './router';

export const initCatalog = (selector = '#js-ci-cd-catalog') => {
  const el = document.querySelector(selector);
  if (!el) {
    return null;
  }

  const { dataset } = el;
  const { ciCatalogPath, reportAbusePath } = dataset;

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(resolvers, { cacheConfig, typeDefs }),
  });

  return new Vue({
    el,
    name: 'GlobalCatalog',
    router: createRouter(ciCatalogPath, CiResourcesPage),
    apolloProvider,
    provide: {
      ciCatalogPath,
      reportAbusePath,
    },
    render(h) {
      return h(GlobalCatalog);
    },
  });
};
