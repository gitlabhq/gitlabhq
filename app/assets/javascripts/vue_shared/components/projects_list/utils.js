import {
  ACTION_COPY_ID,
  ACTION_EDIT,
  ACTION_DELETE,
  ACTION_DELETE_IMMEDIATELY,
  ACTION_RESTORE,
  ACTION_UNARCHIVE,
  ACTION_ARCHIVE,
  ACTION_LEAVE,
} from '~/vue_shared/components/list_actions/constants';
import toast from '~/vue_shared/plugins/global_toast';
import { sprintf, __, s__ } from '~/locale';

export const availableGraphQLProjectActions = ({
  userPermissions,
  markedForDeletion,
  isSelfDeletionInProgress,
  isSelfDeletionScheduled,
  archived,
  isSelfArchived,
}) => {
  // No actions available when project deletion is in progress
  if (isSelfDeletionInProgress) {
    return [];
  }

  // Rules
  const canEdit = userPermissions.viewEditPage;
  const canArchive = userPermissions.archiveProject && !archived && !markedForDeletion;
  const canUnarchive = userPermissions.archiveProject && isSelfArchived;
  const canRestore = userPermissions.removeProject && isSelfDeletionScheduled;
  const { canLeave } = userPermissions;
  // Projects that are not marked for deletion can be deleted (delayed)
  const canDelete = userPermissions.removeProject && !markedForDeletion;
  const canDeleteImmediately = userPermissions.removeProject && isSelfDeletionScheduled;

  // Actions mapped to rules
  const actions = {
    [ACTION_COPY_ID]: true,
    [ACTION_EDIT]: canEdit,
    [ACTION_ARCHIVE]: canArchive,
    [ACTION_UNARCHIVE]: canUnarchive,
    [ACTION_RESTORE]: canRestore,
    [ACTION_DELETE]: canDelete,
    [ACTION_DELETE_IMMEDIATELY]: canDeleteImmediately,
    [ACTION_LEAVE]: canLeave,
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
      sprintf(__('%{project_name} is being deleted.'), {
        project_name: project.name,
      }),
    );

    return;
  }

  toast(
    sprintf(__('%{project_name} moved to pending deletion.'), {
      project_name: project.name,
    }),
  );
};

export const renderLeaveSuccessToast = (project) => {
  toast(
    sprintf(s__('Projects|You left the "%{nameWithNamespace}" project.'), {
      nameWithNamespace: project.nameWithNamespace,
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
