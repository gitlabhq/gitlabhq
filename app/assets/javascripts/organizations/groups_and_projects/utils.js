import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export const formatProjects = (projects) =>
  projects.map(({ id, nameWithNamespace, accessLevel, ...project }) => ({
    ...project,
    id: getIdFromGraphQLId(id),
    name: nameWithNamespace,
    permissions: {
      projectAccess: {
        accessLevel: accessLevel.integerValue,
      },
    },
  }));

export const formatGroups = (groups) =>
  groups.map(({ id, ...group }) => ({
    ...group,
    id: getIdFromGraphQLId(id),
  }));
