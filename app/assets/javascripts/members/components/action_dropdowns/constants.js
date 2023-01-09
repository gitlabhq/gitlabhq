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
  personalProjectOwnerCannotBeRemoved: s__("Members|A personal project's owner cannot be removed."),
  lastGroupOwnerCannotBeRemoved: s__(
    'Members|A group must have at least one owner. To remove the member, assign a new owner.',
  ),
};
