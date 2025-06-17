import Vue from 'vue';
import VueApollo from 'vue-apollo';

import createDefaultClient from '~/lib/graphql';

import AiCatalogApp from './ai_catalog_app.vue';
import { createRouter } from './router';

import userWorkflowsQuery from './graphql/user_workflows.query.graphql';

export const initAiCatalog = (selector = '#js-ai-catalog') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const { dataset } = el;
  const { aiCatalogIndexPath } = dataset;

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  /* eslint-disable @gitlab/require-i18n-strings */
  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: userWorkflowsQuery,
    data: {
      currentUser: {
        id: 1,
        workflows: {
          nodes: [
            {
              id: 1,
              name: 'Workflow 1',
              type: 'Type 1',
            },
            {
              id: 2,
              name: 'Workflow 2',
              type: 'Type 2',
            },
          ],
        },
      },
    },
  });
  /* eslint-enable @gitlab/require-i18n-strings */

  return new Vue({
    el,
    name: 'AiCatalogRoot',
    router: createRouter(aiCatalogIndexPath),
    apolloProvider,
    render(h) {
      return h(AiCatalogApp);
    },
  });
};
