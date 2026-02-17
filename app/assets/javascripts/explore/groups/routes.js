import { EXPLORE_GROUPS_ROUTE_NAME, EXPLORE_GROUPS_TABS } from '~/explore/groups/constants';
import ExploreGroupsApp from '~/explore/groups/components/app.vue';

export default [
  {
    name: EXPLORE_GROUPS_ROUTE_NAME,
    path: '/',
    component: ExploreGroupsApp,
  },
  ...EXPLORE_GROUPS_TABS.map(({ value }) => ({
    name: value,
    path: `/${value}`,
    component: ExploreGroupsApp,
  })),
];
