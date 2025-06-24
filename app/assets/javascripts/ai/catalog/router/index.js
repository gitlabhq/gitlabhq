import Vue from 'vue';
import VueRouter from 'vue-router';
import AiCatalogAgents from '../pages/ai_catalog_agents.vue';
import { AI_CATALOG_INDEX_ROUTE, AI_CATALOG_AGENTS_ROUTE } from './constants';

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
    ],
  });
};
