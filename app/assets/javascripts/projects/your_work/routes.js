import {
  BASE_ROUTE,
  ROOT_ROUTE_NAME,
  DASHBOARD_ROUTE_NAME,
  PROJECTS_DASHBOARD_ROUTE_NAME,
  PROJECT_DASHBOARD_TABS,
} from 'ee_else_ce/projects/your_work/constants';

export default [
  {
    name: ROOT_ROUTE_NAME,
    path: '/',
  },
  {
    name: DASHBOARD_ROUTE_NAME,
    path: '/dashboard',
  },
  {
    name: PROJECTS_DASHBOARD_ROUTE_NAME,
    path: BASE_ROUTE,
  },
  ...PROJECT_DASHBOARD_TABS.map(({ value }) => ({
    name: value,
    path: `${BASE_ROUTE}/${value}`,
  })),
];
