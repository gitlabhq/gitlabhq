import Vue from 'vue';
import VueRouter from 'vue-router';
import List from '~/packages_and_registries/package_registry/pages/list.vue';
import Details from '~/packages_and_registries/package_registry/pages/details.vue';
import { PACKAGE_REGISTRY_TITLE } from '~/packages_and_registries/package_registry/constants';

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
          nameGenerator: () => PACKAGE_REGISTRY_TITLE,
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

  router.afterEach(() => {
    breadCrumbState.updateName('');
  });

  return router;
}
