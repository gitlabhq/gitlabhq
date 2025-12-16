import { BASE_ROUTE, ADMIN_GROUPS_ROUTE_NAME, ADMIN_GROUPS_TABS } from './constants';

import AdminGroupsApp from './components/app.vue';

export default [
  {
    name: ADMIN_GROUPS_ROUTE_NAME,
    path: BASE_ROUTE,
    component: AdminGroupsApp,
  },
  ...ADMIN_GROUPS_TABS.map(({ value }) => ({
    name: value,
    path: `${BASE_ROUTE}${value}`,
    component: AdminGroupsApp,
  })),
];
