import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import toast from '~/vue_shared/plugins/global_toast';
import { sprintf, __ } from '~/locale';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import { QUERY_PARAM_END_CURSOR, QUERY_PARAM_START_CURSOR } from './constants';

const availableProjectActions = (userPermissions) => {
  const baseActions = [];

  if (userPermissions.viewEditPage) {
    baseActions.push(ACTION_EDIT);
  }

  if (userPermissions.removeProject) {
    baseActions.push(ACTION_DELETE);
  }

  return baseActions;
};

const availableGroupActions = (userPermissions) => {
  const baseActions = [ACTION_EDIT];

  if (userPermissions.removeGroup) {
    return [...baseActions, ACTION_DELETE];
  }

  return baseActions;
};

export const formatProjects = (projects) =>
  projects.map(
    ({
      id,
      nameWithNamespace,
      mergeRequestsAccessLevel,
      issuesAccessLevel,
      forkingAccessLevel,
      webUrl,
      userPermissions,
      maxAccessLevel: accessLevel,
      organizationEditPath: editPath,
      ...project
    }) => ({
      ...project,
      id: getIdFromGraphQLId(id),
      name: nameWithNamespace,
      mergeRequestsAccessLevel: mergeRequestsAccessLevel.stringValue,
      issuesAccessLevel: issuesAccessLevel.stringValue,
      forkingAccessLevel: forkingAccessLevel.stringValue,
      webUrl,
      isForked: false,
      accessLevel,
      editPath,
      availableActions: availableProjectActions(userPermissions),
      actionLoadingStates: {
        [ACTION_DELETE]: false,
      },
    }),
  );

export const formatGroups = (groups) =>
  groups.map(({ id, webUrl, parent, maxAccessLevel: accessLevel, userPermissions, ...group }) => ({
    ...group,
    id: getIdFromGraphQLId(id),
    webUrl,
    parent: parent?.id || null,
    accessLevel,
    editPath: `${webUrl}/-/edit`,
    availableActions: availableGroupActions(userPermissions),
    actionLoadingStates: {
      [ACTION_DELETE]: false,
    },
  }));

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

export const renderProjectDeleteSuccessToast = (project) => {
  toast(
    sprintf(__("Project '%{name}' is being deleted."), {
      name: project.name,
    }),
  );
};

export const deleteProjectParams = () => {
  // Overridden in EE
  return {};
};
