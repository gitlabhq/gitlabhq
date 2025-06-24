import Vue from 'vue';
import VueRouter from 'vue-router';
import AiCatalogAgents from '../pages/ai_catalog_agents.vue';
import AiCatalogAgentsShow from '../pages/ai_catalog_agents_show.vue';
import {
  AI_CATALOG_INDEX_ROUTE,
  AI_CATALOG_AGENTS_ROUTE,
  AI_CATALOG_AGENTS_SHOW_ROUTE,
} from './constants';

Vue.use(VueRouter);

export const createRouter = (base) => {
  return new VueRouter({
    base,
    mode: 'history',
    routes: [
      {
        name: AI_CATALOG_INDEX_ROUTE,
        path: '',
        component: AiCatalogAgents,
      },
      {
        name: AI_CATALOG_AGENTS_ROUTE,
        path: '/agents',
        component: AiCatalogAgents,
      },
      {
        name: AI_CATALOG_AGENTS_SHOW_ROUTE,
        path: '/agents/:id',
        component: AiCatalogAgentsShow,
      },
    ],
  });
};
