import Vue from 'vue';
import VueRouter from 'vue-router';
import { HARBOR_REGISTRY_TITLE } from './constants/index';
import List from './pages/list.vue';
import Details from './pages/details.vue';

Vue.use(VueRouter);

export default function createRouter(base, breadCrumbState) {
  const router = new VueRouter({
    base,
    mode: 'history',
    routes: [
      {
        name: 'list',
        path: '/',
        component: List,
        meta: {
          nameGenerator: () => HARBOR_REGISTRY_TITLE,
          root: true,
        },
      },
      {
        name: 'details',
        path: '/:id',
        component: Details,
        meta: {
          nameGenerator: () => breadCrumbState.name,
        },
      },
    ],
  });

  return router;
}
