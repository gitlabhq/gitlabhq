import Vue from 'vue';
import VueRouter from 'vue-router';
import { createRoutes } from 'ee_else_ce/explore/analytics_dashboards/routes';

Vue.use(VueRouter);

export default (basePath, breadcrumbState) => {
  return new VueRouter({
    routes: createRoutes(breadcrumbState),
    mode: 'history',
    base: basePath,
  });
};
