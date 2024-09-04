import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';

const availableGraphQLProjectActions = (userPermissions) => {
  const baseActions = [];

  if (userPermissions.viewEditPage) {
    baseActions.push(ACTION_EDIT);
  }

  if (userPermissions.removeProject) {
    baseActions.push(ACTION_DELETE);
  }

  return baseActions;
};

export const formatGraphQLProjects = (projects) =>
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
      availableActions: availableGraphQLProjectActions(userPermissions),
      actionLoadingStates: {
        [ACTION_DELETE]: false,
      },
    }),
  );
