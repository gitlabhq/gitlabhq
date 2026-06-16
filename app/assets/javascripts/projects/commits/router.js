import Vue from 'vue';
import VueRouter from 'vue-router';
import CommitListApp from '~/projects/commits/components/commit_list_app.vue';

Vue.use(VueRouter);

export const createRouter = (basePath, escapedRef) => {
  const router = new VueRouter({
    mode: 'history',
    base: basePath,
    routes: [
      {
        // Support without decoding as well just in case the ref doesn't need to be decoded
        path: `/${escapedRef}/:path*`,
        name: 'commitsPath',
        component: CommitListApp,
      },
      {
        // Sometimes the ref needs decoding depending on how the backend sends it to us
        path: `/${decodeURI(escapedRef)}/:path*`,
        name: 'commitsPathDecoded',
        component: CommitListApp,
      },
      {
        // Support refs encoded with encodeURIComponent (slashes become %2F).
        // This matches the initial ref when navigated to via the ref selector
        // and then revisited via browser back/forward.
        path: `/${encodeURIComponent(decodeURIComponent(escapedRef))}/:path*`,
        name: 'commitsPathEncoded',
        component: CommitListApp,
      },
      {
        // Wildcard fallback so every URL still matches a route after a ref
        // switch (the specific routes above are hardcoded to the initial ref).
        // The ref is encoded with encodeURIComponent so params.ref is always
        // a single, unambiguous segment — even for refs containing slashes.
        path: '/:ref/:path*',
        name: 'commitsAnyRef',
        component: CommitListApp,
      },
    ],
  });

  return router;
};
