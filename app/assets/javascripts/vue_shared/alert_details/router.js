import Vue from 'vue';
import VueRouter from 'vue-router';
import { joinPaths } from '~/lib/utils/url_utility';

Vue.use(VueRouter);

export default function createRouter(base) {
  const router = new VueRouter({
    mode: 'history',
    base: joinPaths(gon.relative_url_root || '', base),
    routes: [{ path: '/:tabId', name: 'tab' }],
  });

  /* 
    Backward-compatible behavior. Redirects hash mode URLs to history mode ones.
    Ex: from #/overview to /overview
        from #/metrics to /metrics
        from #/activity to /activity
  */
  router.beforeEach((to, _, next) => {
    if (to.hash.startsWith('#/')) {
      const path = to.fullPath.substring(2);
      next(path);
    } else {
      next();
    }
  });

  return router;
}
