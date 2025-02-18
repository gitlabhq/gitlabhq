import { escapeRegExp } from 'lodash';
import Vue from 'vue';
import VueRouter from 'vue-router';
import { joinPaths, webIDEUrl } from '~/lib/utils/url_utility';
import BlobPage from './pages/blob.vue';
import IndexPage from './pages/index.vue';
import TreePage from './pages/tree.vue';
import { getRefType } from './utils/ref_type';

Vue.use(VueRouter);

const normalizePathParam = (pathParam) => {
  // Vue Router 4 when there's more than one `:path` segment
  if (Array.isArray(pathParam)) {
    return joinPaths(...pathParam);
  }

  // Vue Router 3, or when there's zero or one `:path` segments.
  return pathParam?.replace(/^\//, '') || '/';
};

export default function createRouter(base, baseRef) {
  const treePathRoute = {
    component: TreePage,
    props: (route) => ({
      path: normalizePathParam(route.params.path),
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
        path: `/:dash(-)?/tree/${decodeURI(baseRef)}/:path*`,
        ...treePathRoute,
      },
      {
        name: 'treePath',
        // Support without decoding as well just in case the ref doesn't need to be decoded
        path: `/:dash(-)?/tree/${escapeRegExp(baseRef)}/:path*`,
        ...treePathRoute,
      },
      {
        name: 'blobPathDecoded',
        // Sometimes the ref needs decoding depending on how the backend sends it to us
        path: `/:dash(-)?/blob/${decodeURI(baseRef)}/:path*`,
        ...blobPathRoute,
      },
      {
        name: 'blobPath',
        // Support without decoding as well just in case the ref doesn't need to be decoded
        path: `/:dash(-)?/blob/${escapeRegExp(baseRef)}/:path*`,
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
        normalizePathParam(to.params.path),
        needsClosingSlash && '/',
      ),
    );
  });

  return router;
}
