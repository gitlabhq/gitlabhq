import { BASE_ROUTE, SUBGROUPS_AND_PROJECTS_TAB, INACTIVE_TAB } from './constants';

import GroupsShowApp from './components/app.vue';

export default [
  { name: INACTIVE_TAB.value, path: '/groups/:group*/-/inactive', component: GroupsShowApp },
  { name: SUBGROUPS_AND_PROJECTS_TAB.value, path: BASE_ROUTE, component: GroupsShowApp },
];
