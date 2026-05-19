import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { availableGraphQLProjectActions } from '~/vue_shared/components/projects_list/utils';
import { projectPath } from '~/lib/utils/path_helpers/project';

export const formatGraphQLProject = (
  {
    id,
    nameWithNamespace,
    mergeRequestsAccessLevel,
    issuesAccessLevel,
    forkingAccessLevel,
    maxAccessLevel: accessLevel,
    fullPath,
    ...project
  },
  callback = () => {},
) => {
  const baseProject = {
    ...project,
    id: getIdFromGraphQLId(id),
    nameWithNamespace,
    avatarLabel: nameWithNamespace,
    mergeRequestsAccessLevel: mergeRequestsAccessLevel?.stringValue,
    issuesAccessLevel: issuesAccessLevel?.stringValue,
    forkingAccessLevel: forkingAccessLevel?.stringValue,
    isForked: false,
    accessLevel,
    availableActions: availableGraphQLProjectActions(project),
    fullPath,
    relativeWebUrl: projectPath(fullPath),
  };

  return {
    ...baseProject,
    ...callback(baseProject),
  };
};

export const formatGraphQLProjects = (projects, callback = () => {}) =>
  projects.map((project) => formatGraphQLProject(project, callback));
