import {
  ACTION_EDIT,
  ACTION_DELETE,
  ACTION_RESTORE,
  ACTION_UNARCHIVE,
  ACTION_ARCHIVE,
} from '~/vue_shared/components/list_actions/constants';
import toast from '~/vue_shared/plugins/global_toast';
import { sprintf, __ } from '~/locale';

export const availableGraphQLProjectActions = ({
  userPermissions,
  markedForDeletion,
  isSelfDeletionInProgress,
  isSelfDeletionScheduled,
  archived,
}) => {
  // No actions available when project deletion is in progress
  if (isSelfDeletionInProgress) {
    return [];
  }

  const availableActions = [];

  if (userPermissions.viewEditPage) {
    availableActions.push(ACTION_EDIT);
  }

  if (userPermissions.archiveProject) {
    availableActions.push(archived ? ACTION_UNARCHIVE : ACTION_ARCHIVE);
  }

  if (userPermissions.removeProject && isSelfDeletionScheduled) {
    availableActions.push(ACTION_RESTORE);
  }

  if (userPermissions.removeProject) {
    // Projects that are not marked for deletion can be deleted (delayed)
    if (!markedForDeletion) {
      availableActions.push(ACTION_DELETE);
      // Projects with self deletion scheduled can be deleted immediately
    } else if (
      isSelfDeletionScheduled &&
      (userPermissions.adminAllResources || !gon?.features?.disallowImmediateDeletion)
    ) {
      availableActions.push(ACTION_DELETE);
    }
  }

  return availableActions;
};

export const renderArchiveSuccessToast = (project) => {
  toast(
    sprintf(__("Project '%{project_name}' has been successfully archived."), {
      project_name: project.nameWithNamespace,
    }),
  );
};

export const renderUnarchiveSuccessToast = (project) => {
  toast(
    sprintf(__("Project '%{project_name}' has been successfully unarchived."), {
      project_name: project.nameWithNamespace,
    }),
  );
};

export const renderRestoreSuccessToast = (project) => {
  toast(
    sprintf(__("Project '%{project_name}' has been successfully restored."), {
      project_name: project.nameWithNamespace,
    }),
  );
};

export const renderDeleteSuccessToast = (project) => {
  if (project.markedForDeletion) {
    toast(
      sprintf(__("Project '%{project_name}' is being deleted."), {
        project_name: project.nameWithNamespace,
      }),
    );

    return;
  }

  toast(
    sprintf(__("Project '%{project_name}' will be deleted on %{date}."), {
      project_name: project.nameWithNamespace,
      date: project.permanentDeletionDate,
    }),
  );
};

export const deleteParams = (project) => {
  // Project has been marked for delayed deletion so will now be deleted immediately.
  if (project.isSelfDeletionScheduled) {
    return { permanently_remove: true, full_path: project.fullPath };
  }

  return {};
};
