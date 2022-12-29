import { __, s__ } from '~/locale';

export const I18N = {
  actions: __('More actions'),
  editPermissions: s__('Members|Edit permissions'),
  leaveGroup: __('Leave group'),
  removeMember: __('Remove member'),
  confirmNormalUserRemoval: s__(
    'Members|Are you sure you want to remove %{userName} from "%{group}"?',
  ),
  confirmOrphanedUserRemoval: s__(
    'Members|Are you sure you want to remove this orphaned member from "%{group}"?',
  ),
};
