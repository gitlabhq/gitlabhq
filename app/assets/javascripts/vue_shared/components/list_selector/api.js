import Api from '~/api';
import { getProjects } from '~/rest_api';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { ACCESS_LEVEL_REPORTER_INTEGER } from '~/access_level/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import groupsAutocompleteQuery from '~/graphql_shared/queries/groups_autocomplete.query.graphql';
import { buildUrl, GROUPS_PATH } from '~/projects/settings/api/access_dropdown_api';

export const fetchProjectGroups = (projectPath, search) => {
  return Api.projectGroups(projectPath, {
    search,
    with_shared: true,
    shared_min_access_level: ACCESS_LEVEL_REPORTER_INTEGER,
  }).then((data) =>
    data?.map((group) => ({
      text: group.full_name,
      value: group.name,
      ...convertObjectPropsToCamelCase(group),
    })),
  );
};

export const fetchAllGroups = async (apollo, search) => {
  return apollo
    .query({
      query: groupsAutocompleteQuery,
      variables: { search },
    })
    .then(({ data }) =>
      data?.groups.nodes.map((group) => ({
        text: group.fullName,
        value: group.name,
        ...group,
        id: getIdFromGraphQLId(group.id),
        type: 'group',
      })),
    );
};

export const fetchGroupsWithProjectAccess = (projectId, search) => {
  return axios
    .get(buildUrl(gon.relative_url_root || '', GROUPS_PATH), {
      params: {
        project_id: projectId,
        with_project_access: true,
        search,
      },
    })
    .then(({ data }) =>
      data.map((group) => ({
        text: group.name,
        value: group.name,
        ...convertObjectPropsToCamelCase(group),
      })),
    );
};

export const fetchProjects = async (search) => {
  const response = await getProjects(search, { membership: false });
  const projects = response?.data || [];

  return projects.map((project) => ({
    ...convertObjectPropsToCamelCase(project),
    text: project.name,
    value: project.id,
    type: 'project',
  }));
};

export const fetchUsers = async (projectPath, search, usersQueryOptions) => {
  const users = await Api.projectUsers(projectPath, search, usersQueryOptions);

  return users?.map((user) => ({
    text: user.name,
    value: user.username,
    ...convertObjectPropsToCamelCase(user),
  }));
};
