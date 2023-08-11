import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/projects_list/constants';

export const formatProjects = (projects) =>
  projects.map(({ id, nameWithNamespace, accessLevel, webUrl, ...project }) => ({
    ...project,
    id: getIdFromGraphQLId(id),
    name: nameWithNamespace,
    permissions: {
      projectAccess: {
        accessLevel: accessLevel.integerValue,
      },
    },
    webUrl,
    editPath: `${webUrl}/edit`,
    actions: [ACTION_EDIT, ACTION_DELETE],
  }));

export const formatGroups = (groups) =>
  groups.map(({ id, ...group }) => ({
    ...group,
    id: getIdFromGraphQLId(id),
  }));
