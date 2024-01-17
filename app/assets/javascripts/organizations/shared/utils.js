import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';

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
  groups.map(({ id, webUrl, ...group }) => ({
    ...group,
    id: getIdFromGraphQLId(id),
    webUrl,
    editPath: `${webUrl}/-/edit`,
    availableActions: [ACTION_EDIT, ACTION_DELETE],
  }));
