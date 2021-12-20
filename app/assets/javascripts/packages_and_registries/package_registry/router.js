import Vue from 'vue';
import VueRouter from 'vue-router';
import List from '~/packages_and_registries/package_registry/pages/list.vue';

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
      },
    ],
  });

  return router;
}
