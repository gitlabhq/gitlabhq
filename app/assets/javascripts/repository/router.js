import { escapeRegExp } from 'lodash';
import Vue from 'vue';
import VueRouter from 'vue-router';
import { joinPaths, webIDEUrl } from '~/lib/utils/url_utility';
import BlobPage from './pages/blob.vue';
import IndexPage from './pages/index.vue';
import TreePage from './pages/tree.vue';
import { getRefType } from './utils/ref_type';

Vue.use(VueRouter);

export default function createRouter(base, baseRef) {
  const treePathRoute = {
    component: TreePage,
    props: (route) => ({
      path: route.params.path?.replace(/^\//, '') || '/',
      refType: getRefType(route.query.ref_type || null),
    }),
  };

  const blobPathRoute = {
    component: BlobPage,
    props: (route) => {
      return {
        path: route.params.path,
        projectPath: base,
        refType: getRefType(route.query.ref_type || null),
      };
    },
  };

  const router = new VueRouter({
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
        name: 'blobPathDecoded',
        // Sometimes the ref needs decoding depending on how the backend sends it to us
        path: `(/-)?/blob/${decodeURI(baseRef)}/:path*`,
        ...blobPathRoute,
      },
      {
        name: 'blobPath',
        // Support without decoding as well just in case the ref doesn't need to be decoded
        path: `(/-)?/blob/${escapeRegExp(baseRef)}/:path*`,
        ...blobPathRoute,
      },
      {
        path: '/',
        name: 'projectRoot',
        component: IndexPage,
        props: {
          refType: 'HEADS',
        },
        meta: {
          refType: 'HEADS',
        },
      },
    ],
  });

  router.afterEach((to) => {
    const needsClosingSlash = !to.name.includes('blobPath');
    window.gl.webIDEPath = webIDEUrl(
      joinPaths(
        '/',
        base,
        'edit',
        decodeURI(baseRef),
        '-',
        to.params.path || '',
        needsClosingSlash && '/',
      ),
    );
  });

  return router;
}
