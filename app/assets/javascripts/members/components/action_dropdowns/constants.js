import { __, s__ } from '~/locale';

export const I18N = {
  actions: __('More actions'),
  disableTwoFactor: s__('Members|Disable two-factor authentication'),
  editPermissions: s__('Members|Edit permissions'),
  leaveGroup: __('Leave group'),
  leaveProject: __('Leave project'),
  removeMember: __('Remove member'),
  confirmDisableTwoFactor: s__(
    'Members|Are you sure you want to disable the two-factor authentication for %{userName}?',
  ),
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
  banMember: s__('Members|Ban member'),
};
