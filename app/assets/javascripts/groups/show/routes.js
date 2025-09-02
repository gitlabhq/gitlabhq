import { BASE_ROUTE, SUBGROUPS_AND_PROJECTS_TAB } from './constants';

import GroupsShowApp from './components/app.vue';

export default [
  { name: SUBGROUPS_AND_PROJECTS_TAB.value, path: BASE_ROUTE, component: GroupsShowApp },
];
