import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { availableGraphQLProjectActions } from 'ee_else_ce/vue_shared/components/projects_list/utils';

export const formatGraphQLProjects = (projects, callback = () => {}) =>
  projects.map(
    ({
      id,
      nameWithNamespace,
      mergeRequestsAccessLevel,
      issuesAccessLevel,
      forkingAccessLevel,
      maxAccessLevel: accessLevel,
      ...project
    }) => {
      const baseProject = {
        ...project,
        id: getIdFromGraphQLId(id),
        name: nameWithNamespace,
        nameWithNamespace,
        avatarLabel: nameWithNamespace,
        mergeRequestsAccessLevel: mergeRequestsAccessLevel.stringValue,
        issuesAccessLevel: issuesAccessLevel.stringValue,
        forkingAccessLevel: forkingAccessLevel.stringValue,
        isForked: false,
        accessLevel,
        availableActions: availableGraphQLProjectActions(project),
      };

      return {
        ...baseProject,
        ...callback(baseProject),
      };
    },
  );
