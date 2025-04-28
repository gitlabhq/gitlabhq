import {
  ACTION_EDIT,
  ACTION_DELETE,
  ACTION_RESTORE,
  BASE_ACTIONS,
} from '~/vue_shared/components/list_actions/constants';
import toast from '~/vue_shared/plugins/global_toast';
import { sprintf, __ } from '~/locale';

const isAdjournedDeletionEnabled = (project) => {
  // Check if enabled at the project level or globally
  return (
    project.isAdjournedDeletionEnabled ||
    gon?.licensed_features?.adjournedDeletionForProjectsAndGroups
  );
};

export const availableGraphQLProjectActions = ({ userPermissions, markedForDeletionOn }) => {
  const availableActions = [];

  if (userPermissions.viewEditPage) {
    availableActions.push(ACTION_EDIT);
  }

  if (userPermissions.removeProject) {
    availableActions.push(ACTION_DELETE);
  }

  if (userPermissions.removeProject && markedForDeletionOn) {
    availableActions.push(ACTION_RESTORE);
  }

  return availableActions.sort((a, b) => BASE_ACTIONS[a].order - BASE_ACTIONS[b].order);
};

export const renderRestoreSuccessToast = (project) => {
  toast(
    sprintf(__("Project '%{project_name}' has been successfully restored."), {
      project_name: project.nameWithNamespace,
    }),
  );
};

export const renderDeleteSuccessToast = (project) => {
  // Delete immediately if
  // 1. Adjourned deletion is not enabled
  // 2. The project is in a personal namespace
  // 3. The project has already been marked for deletion
  if (!isAdjournedDeletionEnabled(project) || project.isPersonal || project.markedForDeletionOn) {
    toast(
      sprintf(__("Project '%{project_name}' is being deleted."), {
        project_name: project.nameWithNamespace,
      }),
    );

    return;
  }

  // Adjourned deletion is available for the  project
  if (project.isAdjournedDeletionEnabled) {
    toast(
      sprintf(__("Project '%{project_name}' will be deleted on %{date}."), {
        project_name: project.nameWithNamespace,
        date: project.permanentDeletionDate,
      }),
    );

    return;
  }

  // Adjourned deletion is available globally but not at the project level.
  // This means we are deleting a free project. It will be deleted delayed but can only be
  // restored by an admin.
  toast(
    sprintf(__("Deleting project '%{project_name}'. All data will be removed on %{date}."), {
      project_name: project.nameWithNamespace,
      date: project.permanentDeletionDate,
    }),
  );
};

export const deleteParams = (project) => {
  // Project has been marked for delayed deletion so will now be deleted immediately.
  if (project.markedForDeletionOn) {
    return { permanently_remove: true, full_path: project.fullPath };
  }

  return {};
};
