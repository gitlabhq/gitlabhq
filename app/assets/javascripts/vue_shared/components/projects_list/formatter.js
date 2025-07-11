import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { availableGraphQLProjectActions } from '~/vue_shared/components/projects_list/utils';

export const formatGraphQLProjects = (projects, callback = () => {}) =>
  projects.map(
    ({
      id,
      nameWithNamespace,
      mergeRequestsAccessLevel,
      issuesAccessLevel,
      forkingAccessLevel,
      maxAccessLevel: accessLevel,
      group,
      fullPath,
      ...project
    }) => {
      const baseProject = {
        ...project,
        id: getIdFromGraphQLId(id),
        nameWithNamespace,
        avatarLabel: nameWithNamespace,
        mergeRequestsAccessLevel: mergeRequestsAccessLevel.stringValue,
        issuesAccessLevel: issuesAccessLevel.stringValue,
        forkingAccessLevel: forkingAccessLevel.stringValue,
        isForked: false,
        accessLevel,
        availableActions: availableGraphQLProjectActions(project),
        isPersonal: group === null,
        fullPath,
        relativeWebUrl: `/${fullPath}`,
      };

      return {
        ...baseProject,
        ...callback(baseProject),
      };
    },
  );
