import {
  ACTION_REQUEST_ACCESS,
  ACTION_WITHDRAW_ACCESS_REQUEST,
} from '~/vue_shared/components/list_actions/constants';
import { formatGraphQLProject } from '~/vue_shared/components/projects_list/formatter';

function getAvailableActions(
  { availableActions },
  { canWithdrawAccessRequest, canRequestAccess, withdrawAccessRequestPath, requestAccessPath },
) {
  if (canWithdrawAccessRequest && withdrawAccessRequestPath) {
    return [...availableActions, ACTION_WITHDRAW_ACCESS_REQUEST];
  }

  if (canRequestAccess && requestAccessPath) {
    return [...availableActions, ACTION_REQUEST_ACCESS];
  }

  return availableActions;
}

export function formatProject(
  project,
  { canWithdrawAccessRequest, canRequestAccess, requestAccessPath, withdrawAccessRequestPath } = {},
) {
  return formatGraphQLProject(project, (graphqlProject) => ({
    availableActions: getAvailableActions(graphqlProject, {
      canWithdrawAccessRequest,
      canRequestAccess,
      withdrawAccessRequestPath,
      requestAccessPath,
    }),
    withdrawAccessRequestPath,
    requestAccessPath,
  }));
}
