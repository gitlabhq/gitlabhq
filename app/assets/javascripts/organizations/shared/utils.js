import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/formatter';
import { SORT_CREATED_AT, SORT_UPDATED_AT } from './constants';

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
      avatarLabel: fullName,
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

export const formatProjects = (projects) =>
  formatGraphQLProjects(projects, (project) => ({ editPath: project.organizationEditPath }));

export const timestampType = (sortName) => {
  const SORT_MAP = {
    [SORT_CREATED_AT]: TIMESTAMP_TYPE_CREATED_AT,
    [SORT_UPDATED_AT]: TIMESTAMP_TYPE_UPDATED_AT,
  };

  return SORT_MAP[sortName] || TIMESTAMP_TYPE_CREATED_AT;
};
