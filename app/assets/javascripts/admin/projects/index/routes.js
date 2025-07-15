import { BASE_ROUTE, ADMIN_PROJECTS_ROUTE_NAME, ADMIN_PROJECTS_TABS } from './constants';

import AdminProjectsApp from './components/app.vue';

export default [
  {
    name: ADMIN_PROJECTS_ROUTE_NAME,
    path: BASE_ROUTE,
    component: AdminProjectsApp,
  },
  ...ADMIN_PROJECTS_TABS.map(({ value }) => ({
    name: value,
    path: `${BASE_ROUTE}/${value}`,
    component: AdminProjectsApp,
  })),
];
