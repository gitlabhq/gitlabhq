import { __ } from '~/locale';
import UserItem from './user_item.vue';
import GroupItem from './group_item.vue';
import DeployKeyItem from './deploy_key_item.vue';

export const CONFIG = {
  users: {
    title: __('Users'),
    icon: 'user',
    filterKey: 'username',
    showNamespaceDropdown: true,
    component: UserItem,
  },
  groups: {
    title: __('Groups'),
    icon: 'group',
    filterKey: 'name',
    component: GroupItem,
  },
  deployKeys: {
    title: __('Deploy keys'),
    icon: 'key',
    filterKey: 'name',
    component: DeployKeyItem,
  },
};
