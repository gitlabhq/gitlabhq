import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { cacheConfig, resolvers } from '~/ci/catalog/graphql/settings';
import typeDefs from '~/ci/catalog/graphql/typedefs.graphql';
import { injectVueAppBreadcrumbs } from '~/lib/utils/breadcrumbs';

import GlobalCatalog from './global_catalog.vue';
import CiResourcesPage from './components/pages/ci_resources_page.vue';
import CiCatalogBreadcrumb from './components/ci_catalog_breadcrumb.vue';
import { createRouter } from './router';

export const initCatalog = (selector = '#js-ci-cd-catalog') => {
  const el = document.querySelector(selector);
  if (!el) {
    return null;
  }

  const { dataset } = el;
  const { ciCatalogPath, reportAbusePath, legalDisclaimer } = dataset;

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(resolvers, { cacheConfig, typeDefs }),
  });

  const router = createRouter(ciCatalogPath, CiResourcesPage);

  injectVueAppBreadcrumbs(router, CiCatalogBreadcrumb);

  return new Vue({
    el,
    name: 'GlobalCatalog',
    router,
    apolloProvider,
    provide: {
      ciCatalogPath,
      reportAbusePath,
      legalDisclaimer,
    },
    render(h) {
      return h(GlobalCatalog);
    },
  });
};
