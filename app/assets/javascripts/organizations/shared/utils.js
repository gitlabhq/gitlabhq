import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import toast from '~/vue_shared/plugins/global_toast';
import { sprintf, __ } from '~/locale';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import {
  SORT_CREATED_AT,
  SORT_UPDATED_AT,
  QUERY_PARAM_END_CURSOR,
  QUERY_PARAM_START_CURSOR,
} from './constants';

const availableGroupActions = (userPermissions) => {
  const baseActions = [];

  if (userPermissions.viewEditPage) {
    baseActions.push(ACTION_EDIT);
  }

  if (userPermissions.removeGroup) {
    baseActions.push(ACTION_DELETE);
  }

  return baseActions;
};

export const formatGroups = (groups) =>
  groups.map(
    ({
      id,
      fullName,
      webUrl,
      parent,
      maxAccessLevel: accessLevel,
      userPermissions,
      organizationEditPath: editPath,
      ...group
    }) => ({
      ...group,
      id: getIdFromGraphQLId(id),
      name: fullName,
      fullName,
      webUrl,
      parent: parent?.id || null,
      accessLevel,
      editPath,
      availableActions: availableGroupActions(userPermissions),
      actionLoadingStates: {
        [ACTION_DELETE]: false,
      },
    }),
  );

export const onPageChange = ({
  startCursor,
  endCursor,
  routeQuery: { start_cursor, end_cursor, ...routeQuery },
}) => {
  if (startCursor) {
    return {
      ...routeQuery,
      [QUERY_PARAM_START_CURSOR]: startCursor,
    };
  }

  if (endCursor) {
    return {
      ...routeQuery,
      [QUERY_PARAM_END_CURSOR]: endCursor,
    };
  }

  return routeQuery;
};

export const renderDeleteSuccessToast = (item, type) => {
  toast(
    sprintf(__("%{type} '%{name}' is being deleted."), {
      type,
      name: item.name,
    }),
  );
};

export const timestampType = (sortName) => {
  const SORT_MAP = {
    [SORT_CREATED_AT]: TIMESTAMP_TYPE_CREATED_AT,
    [SORT_UPDATED_AT]: TIMESTAMP_TYPE_UPDATED_AT,
  };

  return SORT_MAP[sortName] || TIMESTAMP_TYPE_CREATED_AT;
};

export const deleteParams = () => {
  // Overridden in EE
  return {};
};
