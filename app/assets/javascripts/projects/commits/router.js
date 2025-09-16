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
    ],
  });

  return router;
};
