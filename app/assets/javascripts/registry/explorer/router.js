import Vue from 'vue';
import VueRouter from 'vue-router';
import { __ } from '~/locale';
import List from './pages/list.vue';
import Details from './pages/details.vue';

Vue.use(VueRouter);

export default function createRouter(base, store) {
  const router = new VueRouter({
    base,
    mode: 'history',
    routes: [
      {
        name: 'list',
        path: '/',
        component: List,
        meta: {
          name: __('Container Registry'),
        },
        beforeEnter: (to, from, next) => {
          store.dispatch('requestImagesList');
          next();
        },
      },
      {
        name: 'details',
        path: '/:id',
        component: Details,
        meta: {
          name: __('Tags'),
        },
        beforeEnter: (to, from, next) => {
          store.dispatch('requestTagsList', { id: to.params.id });
          next();
        },
      },
    ],
  });

  return router;
}
