import {
  SUBGROUPS_AND_PROJECTS_TAB,
  SHARED_GROUPS_TAB,
  INACTIVE_TAB,
  SHARED_PROJECTS_TAB,
} from './constants';

import GroupsShowApp from './components/app.vue';

export default [
  {
    name: SHARED_PROJECTS_TAB.value,
    path: '/groups/:group*/-/shared',
    alias: '/:group*/-/shared',
    component: GroupsShowApp,
  },
  {
    name: SHARED_GROUPS_TAB.value,
    path: '/groups/:group*/-/shared_groups',
    alias: '/:group*/-/shared_groups',
    component: GroupsShowApp,
  },
  {
    name: INACTIVE_TAB.value,
    path: '/groups/:group*/-/inactive',
    alias: '/:group*/-/inactive',
    component: GroupsShowApp,
  },
  {
    name: SUBGROUPS_AND_PROJECTS_TAB.value,
    path: '/groups/:group*',
    alias: '/:group*',
    component: GroupsShowApp,
  },
];
