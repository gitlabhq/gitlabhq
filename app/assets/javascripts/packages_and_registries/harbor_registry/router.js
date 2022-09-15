import Vue from 'vue';
import VueRouter from 'vue-router';
import { HARBOR_REGISTRY_TITLE } from './constants/index';
import List from './pages/list.vue';
import Details from './pages/details.vue';
import HarborTags from './pages/harbor_tags.vue';

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
        path: '/:project/:image',
        component: Details,
        meta: {
          nameGenerator: () => breadCrumbState.name,
          hrefGenerator: () => breadCrumbState.href,
        },
      },
      {
        name: 'tags',
        path: '/:project/:image/:digest',
        component: HarborTags,
        meta: {
          nameGenerator: () => breadCrumbState.name,
          hrefGenerator: () => breadCrumbState.href,
        },
      },
    ],
  });

  return router;
}
