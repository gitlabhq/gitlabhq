import Vue from 'vue';
import VueRouter from 'vue-router';
import { escapeRegExp } from 'lodash';
import { joinPaths } from '../lib/utils/url_utility';
import IndexPage from './pages/index.vue';
import TreePage from './pages/tree.vue';

Vue.use(VueRouter);

export default function createRouter(base, baseRef) {
  const treePathRoute = {
    component: TreePage,
    props: route => ({
      path: route.params.path?.replace(/^\//, '') || '/',
    }),
  };

  return new VueRouter({
    mode: 'history',
    base: joinPaths(gon.relative_url_root || '', base),
    routes: [
      {
        name: 'treePathDecoded',
        // Sometimes the ref needs decoding depending on how the backend sends it to us
        path: `(/-)?/tree/${decodeURI(baseRef)}/:path*`,
        ...treePathRoute,
      },
      {
        name: 'treePath',
        // Support without decoding as well just in case the ref doesn't need to be decoded
        path: `(/-)?/tree/${escapeRegExp(baseRef)}/:path*`,
        ...treePathRoute,
      },
      {
        path: '/',
        name: 'projectRoot',
        component: IndexPage,
      },
    ],
  });
}
