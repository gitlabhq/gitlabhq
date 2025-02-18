import toast from '~/vue_shared/plugins/global_toast';
import { sprintf, __ } from '~/locale';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';

export const availableGraphQLProjectActions = ({ userPermissions }) => {
  const baseActions = [];

  if (userPermissions.viewEditPage) {
    baseActions.push(ACTION_EDIT);
  }

  if (userPermissions.removeProject) {
    baseActions.push(ACTION_DELETE);
  }

  return baseActions;
};

export const renderDeleteSuccessToast = (project) => {
  toast(
    sprintf(__("Project '%{project_name}' is being deleted."), {
      project_name: project.name,
    }),
  );
};

export const deleteParams = () => {
  // Overridden in EE
  return {};
};
