import Vue from 'vue';
import VueApollo from 'vue-apollo';

import createDefaultClient from '~/lib/graphql';

import AiCatalogApp from './ai_catalog_app.vue';
import { createRouter } from './router';

import aiCatalogAgentsQuery from './graphql/ai_catalog_agents.query.graphql';

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
    query: aiCatalogAgentsQuery,
    data: {
      aiCatalogAgents: {
        nodes: [
          {
            id: 1,
            type: 'agent',
            name: 'Claude Sonnet 4',
            description: 'Smart, efficient model for everyday user',
            model: 'claude-sonnet-4-20250514',
            verified: true,
            version: 'v4.2',
            releasedAt: new Date(),
          },
          {
            id: 2,
            type: 'agent',
            name: 'Claude Opus 4',
            description: 'Powerful, large model for complex challenges',
            model: 'claude-opus-4-20250514',
            verified: true,
            version: 'v4.2',
            releasedAt: new Date(),
          },
        ],
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
