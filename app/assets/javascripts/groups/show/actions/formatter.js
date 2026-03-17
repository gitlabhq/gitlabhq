import {
  formatGraphQLGroup,
  formatGroupForGraphQLResolver,
} from '~/vue_shared/components/groups_list/formatter';
import {
  ACTION_REQUEST_ACCESS,
  ACTION_WITHDRAW_ACCESS_REQUEST,
} from '~/vue_shared/components/list_actions/constants';

function getAvailableActions(
  { availableActions, requestAccessPath, withdrawAccessRequestPath },
  canWithdrawAccessRequest,
  canRequestAccess,
) {
  if (canWithdrawAccessRequest && withdrawAccessRequestPath) {
    return [...availableActions, ACTION_WITHDRAW_ACCESS_REQUEST];
  }

  if (canRequestAccess && requestAccessPath) {
    return [...availableActions, ACTION_REQUEST_ACCESS];
  }

  return availableActions;
}

export function formatGroup(group, { canWithdrawAccessRequest, canRequestAccess } = {}) {
  const resolverGroup = formatGroupForGraphQLResolver(group);

  return formatGraphQLGroup(resolverGroup, (graphqlGroup) => ({
    availableActions: getAvailableActions(graphqlGroup, canWithdrawAccessRequest, canRequestAccess),
  }));
}
