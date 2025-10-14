import { GROUPS_DASHBOARD_ROUTE_NAME, GROUP_DASHBOARD_TABS } from './constants';

import YourWorkGroupsApp from './components/app.vue';

export default [
  {
    name: GROUPS_DASHBOARD_ROUTE_NAME,
    path: '/',
    component: YourWorkGroupsApp,
  },
  ...GROUP_DASHBOARD_TABS.map(({ value }) => ({
    name: value,
    path: `/${value}`,
    component: YourWorkGroupsApp,
  })),
];
