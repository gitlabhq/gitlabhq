import toast from '~/vue_shared/plugins/global_toast';
import { sprintf, __ } from '~/locale';

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

export const deleteParams = (item) => {
  // If delayed deletion is disabled or the project/group is not yet marked for deletion
  if (!item.isAdjournedDeletionEnabled || !item.markedForDeletionOn) {
    return {};
  }

  return { permanently_remove: true };
};
