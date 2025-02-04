import {
  BASE_ROUTE,
  ROOT_ROUTE_NAME,
  DASHBOARD_ROUTE_NAME,
  PROJECTS_DASHBOARD_ROUTE_NAME,
  PROJECT_DASHBOARD_TABS,
} from './constants';

import YourWorkProjectsApp from './components/app.vue';

export default [
  {
    name: ROOT_ROUTE_NAME,
    path: '/',
    component: YourWorkProjectsApp,
  },
  {
    name: DASHBOARD_ROUTE_NAME,
    path: '/dashboard',
    component: YourWorkProjectsApp,
  },
  {
    name: PROJECTS_DASHBOARD_ROUTE_NAME,
    path: BASE_ROUTE,
    component: YourWorkProjectsApp,
  },
  ...PROJECT_DASHBOARD_TABS.map(({ value }) => ({
    name: value,
    path: `${BASE_ROUTE}/${value}`,
    component: YourWorkProjectsApp,
  })),
];
