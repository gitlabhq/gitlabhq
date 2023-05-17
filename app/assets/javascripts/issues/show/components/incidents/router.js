import Vue from 'vue';
import VueRouter from 'vue-router';

Vue.use(VueRouter);

export default (currentPath, currentTab = null) => {
  // If navigating directly to a tab, determine the base
  // path to initialize router, then set the current route.
  const base = currentPath.replace(new RegExp(`/${currentTab}$`), '');

  const router = new VueRouter({
    mode: 'history',
    base,
    routes: [{ path: '/:tabId', name: 'tab' }],
  });

  if (currentTab) router.push(`/${currentTab}`);

  return router;
};
