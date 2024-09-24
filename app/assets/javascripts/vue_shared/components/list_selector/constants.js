import { __ } from '~/locale';
import UserItem from './user_item.vue';
import GroupItem from './group_item.vue';
import DeployKeyItem from './deploy_key_item.vue';
import ProjectItem from './project_item.vue';

export const USERS_TYPE = 'users';
export const GROUPS_TYPE = 'groups';
export const DEPLOY_KEYS_TYPE = 'deployKeys';
export const PROJECTS_TYPE = 'projects';

export const CONFIG = {
  users: {
    title: __('Users'),
    icon: 'user',
    filterKey: 'username',
    component: UserItem,
  },
  groups: {
    title: __('Groups'),
    icon: 'group',
    filterKey: 'id',
    showNamespaceDropdown: true,
    component: GroupItem,
  },
  deployKeys: {
    title: __('Deploy keys'),
    icon: 'key',
    filterKey: 'id',
    component: DeployKeyItem,
  },
  projects: {
    title: __('Projects'),
    icon: 'project',
    filterKey: 'id',
    component: ProjectItem,
  },
};
