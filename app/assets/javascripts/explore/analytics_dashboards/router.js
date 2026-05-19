import Vue from 'vue';
import VueRouter from 'vue-router';
import { s__ } from '~/locale';
import DashboardView from './pages/details.vue';
import DashboardsList from './pages/list.vue';

Vue.use(VueRouter);

export default (basePath, breadcrumbState) => {
  return new VueRouter({
    routes: [
      {
        name: 'root',
        path: '/',
        component: DashboardsList,
        meta: {
          getName: () => s__('Analytics|Analytics dashboards'),
          root: true,
        },
      },
      {
        name: 'dashboard-detail',
        path: '/:slug',
        component: DashboardView,
        meta: {
          getName: () => breadcrumbState.name,
        },
      },
    ],
    mode: 'history',
    base: basePath,
  });
};
