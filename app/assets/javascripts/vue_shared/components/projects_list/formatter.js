import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { availableGraphQLProjectActions } from 'ee_else_ce/vue_shared/components/projects_list/utils';

export const formatGraphQLProjects = (projects) =>
  projects.map(
    ({
      id,
      nameWithNamespace,
      mergeRequestsAccessLevel,
      issuesAccessLevel,
      forkingAccessLevel,
      webUrl,
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
      availableActions: availableGraphQLProjectActions(project),
    }),
  );
