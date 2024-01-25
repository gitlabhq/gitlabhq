import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import { QUERY_PARAM_END_CURSOR, QUERY_PARAM_START_CURSOR } from './constants';

export const formatProjects = (projects) =>
  projects.map(
    ({
      id,
      nameWithNamespace,
      mergeRequestsAccessLevel,
      issuesAccessLevel,
      forkingAccessLevel,
      webUrl,
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
      editPath: `${webUrl}/edit`,
      availableActions: [ACTION_EDIT, ACTION_DELETE],
    }),
  );

export const formatGroups = (groups) =>
  groups.map(({ id, webUrl, parent, ...group }) => ({
    ...group,
    id: getIdFromGraphQLId(id),
    webUrl,
    parent: parent?.id || null,
    editPath: `${webUrl}/-/edit`,
    availableActions: [ACTION_EDIT, ACTION_DELETE],
  }));

export const onPageChange = ({
  startCursor,
  endCursor,
  hasPreviousPage,
  routeQuery: { start_cursor, end_cursor, ...routeQuery },
}) => {
  if (startCursor && hasPreviousPage) {
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
