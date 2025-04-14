import { BASE_ROUTE, GROUPS_DASHBOARD_ROUTE_NAME, GROUP_DASHBOARD_TABS } from './constants';

import YourWorkGroupsApp from './components/app.vue';

export default [
  {
    name: GROUPS_DASHBOARD_ROUTE_NAME,
    path: BASE_ROUTE,
    component: YourWorkGroupsApp,
  },
  ...GROUP_DASHBOARD_TABS.map(({ value }) => ({
    name: value,
    path: `${BASE_ROUTE}/${value}`,
    component: YourWorkGroupsApp,
  })),
];
