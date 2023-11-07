import { __ } from '~/locale';

export const CONFIG = {
  users: { title: __('Users'), icon: 'user', filterKey: 'username', showNamespaceDropdown: true },
  groups: { title: __('Groups'), icon: 'group', filterKey: 'name' },
};
