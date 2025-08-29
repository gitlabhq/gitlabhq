import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { availableGraphQLProjectActions } from '~/vue_shared/components/projects_list/utils';
import { joinPaths } from '~/lib/utils/url_utility';

export const formatGraphQLProject = (
  {
    id,
    nameWithNamespace,
    mergeRequestsAccessLevel,
    issuesAccessLevel,
    forkingAccessLevel,
    maxAccessLevel: accessLevel,
    group,
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
    mergeRequestsAccessLevel: mergeRequestsAccessLevel.stringValue,
    issuesAccessLevel: issuesAccessLevel.stringValue,
    forkingAccessLevel: forkingAccessLevel.stringValue,
    isForked: false,
    accessLevel,
    availableActions: availableGraphQLProjectActions(project),
    isPersonal: group === null,
    fullPath,
    relativeWebUrl: joinPaths('/', gon.relative_url_root, fullPath),
  };

  return {
    ...baseProject,
    ...callback(baseProject),
  };
};

export const formatGraphQLProjects = (projects, callback = () => {}) =>
  projects.map((project) => formatGraphQLProject(project, callback));
