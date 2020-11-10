import Vue from 'vue';
import VueRouter from 'vue-router';
import List from './pages/list.vue';
import Details from './pages/details.vue';
import { CONTAINER_REGISTRY_TITLE } from './constants/index';

Vue.use(VueRouter);

export default function createRouter(base) {
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
          nameGenerator: ({ imageDetails }) => imageDetails?.name,
        },
      },
    ],
  });

  return router;
}
