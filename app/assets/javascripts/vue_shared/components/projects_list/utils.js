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
