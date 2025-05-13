import toast from '~/vue_shared/plugins/global_toast';
import { sprintf, __ } from '~/locale';
import {
  ACTION_EDIT,
  ACTION_DELETE,
  ACTION_LEAVE,
  ACTION_RESTORE,
} from '~/vue_shared/components/list_actions/constants';

export const availableGraphQLGroupActions = ({ userPermissions, markedForDeletionOn }) => {
  const baseActions = [];

  if (userPermissions.viewEditPage) {
    baseActions.push(ACTION_EDIT);
  }

  if (userPermissions.removeGroup && markedForDeletionOn) {
    baseActions.push(ACTION_RESTORE);
  }

  if (userPermissions.canLeave) {
    baseActions.push(ACTION_LEAVE);
  }

  if (userPermissions.removeGroup) {
    baseActions.push(ACTION_DELETE);
  }

  return baseActions;
};

export const renderDeleteSuccessToast = (item) => {
  // If delayed deletion is disabled or the project/group is already marked for deletion
  if (!item.isAdjournedDeletionEnabled || item.markedForDeletionOn) {
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
    sprintf(__("Left the '%{group_name}' group successfully."), {
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

export const deleteParams = (item) => {
  // If delayed deletion is disabled or the project/group is not yet marked for deletion
  if (!item.isAdjournedDeletionEnabled || !item.markedForDeletionOn) {
    return {};
  }

  return { permanently_remove: true };
};
