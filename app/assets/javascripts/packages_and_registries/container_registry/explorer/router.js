import Vue from 'vue';
import VueRouter from 'vue-router';
import { CONTAINER_REGISTRY_TITLE } from './constants/index';
import Details from './pages/details.vue';
import List from './pages/list.vue';

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
          nameGenerator: () => CONTAINER_REGISTRY_TITLE,
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
