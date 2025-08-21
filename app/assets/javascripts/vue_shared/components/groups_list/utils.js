import toast from '~/vue_shared/plugins/global_toast';
import { sprintf, __ } from '~/locale';
import {
  ACTION_EDIT,
  ACTION_DELETE,
  ACTION_DELETE_IMMEDIATELY,
  ACTION_LEAVE,
  ACTION_RESTORE,
  ACTION_ARCHIVE,
  ACTION_UNARCHIVE,
} from '~/vue_shared/components/list_actions/constants';

export const availableGraphQLGroupActions = ({
  userPermissions,
  markedForDeletion,
  isSelfDeletionInProgress,
  isSelfDeletionScheduled,
  archived,
}) => {
  // No actions available when group deletion is in progress
  if (isSelfDeletionInProgress) {
    return [];
  }

  const baseActions = [];

  if (userPermissions.viewEditPage) {
    baseActions.push(ACTION_EDIT);
  }

  if (userPermissions.archiveGroup) {
    baseActions.push(archived ? ACTION_UNARCHIVE : ACTION_ARCHIVE);
  }

  if (userPermissions.removeGroup && isSelfDeletionScheduled) {
    baseActions.push(ACTION_RESTORE);
  }

  if (userPermissions.canLeave) {
    baseActions.push(ACTION_LEAVE);
  }

  if (userPermissions.removeGroup) {
    // Groups that are not marked for deletion can be deleted (delayed)
    if (!markedForDeletion) {
      baseActions.push(ACTION_DELETE);
      // Groups with self deletion scheduled can be deleted immediately
    } else if (isSelfDeletionScheduled) {
      baseActions.push(ACTION_DELETE_IMMEDIATELY);
    }
  }

  return baseActions;
};

export const renderDeleteSuccessToast = (item) => {
  // If the project/group is already marked for deletion
  if (item.markedForDeletion) {
    toast(
      sprintf(__("Group '%{group_name}' is being deleted."), {
        group_name: item.fullName,
      }),
    );

    return;
  }

  toast(
    sprintf(__("Group '%{group_name}' will be deleted on %{date}."), {
      group_name: item.fullName,
      date: item.permanentDeletionDate,
    }),
  );
};

export const renderLeaveSuccessToast = (group) => {
  toast(
    sprintf(__('You left the "%{group_name}" group.'), {
      group_name: group.fullName,
    }),
  );
};

export const renderRestoreSuccessToast = (group) => {
  toast(
    sprintf(__("Group '%{group_name}' has been successfully restored."), {
      group_name: group.fullName,
    }),
  );
};

export const renderArchiveSuccessToast = (group) => {
  toast(
    sprintf(__("Group '%{group_name}' has been successfully archived."), {
      group_name: group.fullName,
    }),
  );
};

export const renderUnarchiveSuccessToast = (group) => {
  toast(
    sprintf(__("Group '%{group_name}' has been successfully unarchived."), {
      group_name: group.fullName,
    }),
  );
};

export const deleteParams = (item) => {
  // If the project/group is not yet marked for deletion
  if (!item.markedForDeletion) {
    return {};
  }

  return { permanently_remove: true };
};
