import { __ } from '~/locale';
import UserItem from './user_item.vue';
import GroupItem from './group_item.vue';
import DeployKeyItem from './deploy_key_item.vue';
import ProjectItem from './project_item.vue';

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
    filterKey: 'name',
    showNamespaceDropdown: true,
    component: GroupItem,
  },
  deployKeys: {
    title: __('Deploy keys'),
    icon: 'key',
    filterKey: 'name',
    component: DeployKeyItem,
  },
  projects: {
    title: __('Projects'),
    icon: 'project',
    filterKey: 'id',
    component: ProjectItem,
  },
};
