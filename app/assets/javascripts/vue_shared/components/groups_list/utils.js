import toast from '~/vue_shared/plugins/global_toast';
import { sprintf, __ } from '~/locale';
import {
  ACTION_COPY_ID,
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

  // Rules
  const canEdit = userPermissions.viewEditPage;
  const canArchive = userPermissions.archiveGroup && !archived && gon.features?.archiveGroup;
  const canUnarchive = userPermissions.archiveGroup && archived;
  const canRestore = userPermissions.removeGroup && isSelfDeletionScheduled;
  const { canLeave } = userPermissions;
  // Groups that are not marked for deletion can be deleted (delayed)
  const canDelete = userPermissions.removeGroup && !markedForDeletion;
  // Groups with self deletion scheduled can be deleted immediately if the
  // allow_immediate_namespaces_deletion application setting is enabled
  const canDeleteImmediately =
    userPermissions.removeGroup &&
    isSelfDeletionScheduled &&
    gon?.allow_immediate_namespaces_deletion;

  // Actions mapped to rules
  const actions = {
    [ACTION_COPY_ID]: true,
    [ACTION_EDIT]: canEdit,
    [ACTION_ARCHIVE]: canArchive,
    [ACTION_UNARCHIVE]: canUnarchive,
    [ACTION_RESTORE]: canRestore,
    [ACTION_LEAVE]: canLeave,
    [ACTION_DELETE]: canDelete,
    [ACTION_DELETE_IMMEDIATELY]: canDeleteImmediately,
  };

  const availableActions = Object.entries(actions).flatMap(([action, isAvailable]) =>
    isAvailable ? [action] : [],
  );

  return availableActions;
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
