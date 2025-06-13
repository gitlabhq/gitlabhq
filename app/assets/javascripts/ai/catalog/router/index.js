import Vue from 'vue';
import VueRouter from 'vue-router';
import AiCatalogIndex from '../pages/ai_catalog_index.vue';
import { AI_CATALOG_INDEX_ROUTE } from './constants';

Vue.use(VueRouter);

export const createRouter = (base) => {
  return new VueRouter({
    base,
    mode: 'history',
    routes: [
      {
        name: AI_CATALOG_INDEX_ROUTE,
        path: '',
        component: AiCatalogIndex,
      },
    ],
  });
};
