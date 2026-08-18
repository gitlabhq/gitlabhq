import { s__ } from '~/locale';
import DashboardsList from 'ee_else_ce/explore/analytics_dashboards/pages/list.vue';
import DashboardView from 'ee_else_ce/explore/analytics_dashboards/pages/details.vue';

export const createRoutes = (breadcrumbState) => [
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
];
