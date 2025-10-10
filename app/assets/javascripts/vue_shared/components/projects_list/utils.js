import {
  ACTION_EDIT,
  ACTION_DELETE,
  ACTION_DELETE_IMMEDIATELY,
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

  // Rules
  const canEdit = userPermissions.viewEditPage;
  const canArchive = userPermissions.archiveProject && !archived;
  const canUnarchive = userPermissions.archiveProject && archived;
  const canRestore = userPermissions.removeProject && isSelfDeletionScheduled;
  // Projects that are not marked for deletion can be deleted (delayed)
  const canDelete = userPermissions.removeProject && !markedForDeletion;
  // Projects with self deletion scheduled can be deleted immediately if the
  // allow_immediate_namespaces_deletion application setting is enabled
  const canDeleteImmediately =
    userPermissions.removeProject &&
    isSelfDeletionScheduled &&
    gon?.allow_immediate_namespaces_deletion;

  // Actions mapped to rules
  const actions = {
    [ACTION_EDIT]: canEdit,
    [ACTION_ARCHIVE]: canArchive,
    [ACTION_UNARCHIVE]: canUnarchive,
    [ACTION_RESTORE]: canRestore,
    [ACTION_DELETE]: canDelete,
    [ACTION_DELETE_IMMEDIATELY]: canDeleteImmediately,
  };

  const availableActions = Object.entries(actions).flatMap(([action, isAvailable]) =>
    isAvailable ? [action] : [],
  );

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
