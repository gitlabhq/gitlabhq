export const mockGroupPermissions = [
  {
    name: 'read_project',
    description: 'Grants the ability to read projects',
    action: 'read',
    category: 'groups_and_projects',
    categoryName: 'Groups and projects',
    resource: 'project',
    resourceName: 'Project',
    resourceDescription: 'Project resource description',
    boundaries: ['GROUP', 'PROJECT'],
  },
  {
    name: 'write_project',
    description: 'Grants the ability to write to projects',
    action: 'write',
    category: 'groups_and_projects',
    categoryName: 'Groups and projects',
    resource: 'project',
    resourceName: 'Project',
    resourceDescription: 'Project resource description',
    boundaries: ['GROUP', 'PROJECT'],
  },
  {
    name: 'read_repository',
    description: 'Grants the ability to read repository',
    action: 'read',
    category: 'merge_request',
    categoryName: 'Merge request',
    resource: 'repository',
    resourceName: 'Repository',
    resourceDescription: 'Repository resource description',
    boundaries: ['PROJECT'],
  },
  {
    name: 'read_contributed_project',
    description: 'Grants the ability to read contributed project',
    action: 'read',
    category: 'groups_and_projects',
    categoryName: 'Groups and projects',
    resource: 'contributed_project',
    resourceName: 'Contributed project',
    resourceDescription: 'Contributed project resource description',
    boundaries: ['GROUP', 'PROJECT'],
  },
];

export const mockGroupResources = ['project', 'repository', 'contributed_project'];

export const mockUserPermissions = [
  {
    name: 'read_user',
    description: 'Grants the ability to read user data',
    action: 'read',
    category: 'user_access',
    categoryName: 'User access',
    resource: 'user',
    resourceName: 'User',
    resourceDescription: 'User resource description',
    boundaries: ['USER'],
  },
  {
    name: 'read_contributed_project',
    description: 'Grants the ability to view projects user has contributed to',
    action: 'read_contributed',
    category: 'projects',
    categoryName: 'Projects',
    resource: 'project',
    resourceName: 'Project',
    resourceDescription: 'Project resource description',
    boundaries: ['USER'],
  },
];

export const mockUserResources = ['user', 'project'];

export const mockGroups = [
  {
    id: 'gid://gitlab/Group/1',
    name: 'Test Group 1',
    fullPath: 'test-group-1',
    descendantGroupsCount: 2,
    projectsCount: 5,
    __typename: 'Group',
  },
  {
    id: 'gid://gitlab/Group/2',
    name: 'Test Group 2',
    fullPath: 'test-group-2',
    descendantGroupsCount: 0,
    projectsCount: 3,
    __typename: 'Group',
  },
];

export const mockProjects = [
  {
    id: 'gid://gitlab/Project/1',
    name: 'Test Project 1',
    fullPath: 'test-group-1/test-project-1',
    __typename: 'Project',
  },
  {
    id: 'gid://gitlab/Project/2',
    name: 'Test Project 2',
    fullPath: 'test-group-2/test-project-2',
    __typename: 'Project',
  },
];

export const mockInstancePermissions = [
  {
    name: 'read_compliance_policy_setting',
    description: 'Grants the ability to read compliance policy settings',
    action: 'read',
    category: 'application_security',
    categoryName: 'Application security',
    resource: 'compliance_policy_setting',
    resourceName: 'Compliance policy setting',
    resourceDescription: 'Grants the ability to read and update compliance policy settings.',
    boundaries: ['INSTANCE'],
  },
];

export const mockAccessTokenPermissionsQueryResponse = {
  data: {
    accessTokenPermissions: [
      ...mockGroupPermissions,
      ...mockUserPermissions,
      ...mockInstancePermissions,
    ],
  },
};
