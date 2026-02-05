export const mockGranularGroupScope = {
  access: 'SELECTED_MEMBERSHIPS',
  namespace: {
    id: 'gid://gitlab/Group/1',
    fullName: 'My Group',
    fullPath: 'my-group',
    webUrl: 'https://gitlab.com/groups/my-group',
    avatarUrl: '/avatar.png',
  },
  permissions: [
    { resource: 'project', action: 'read' },
    { resource: 'project', action: 'write' },
    { resource: 'group', action: 'admin' },
  ],
  __typename: 'AccessTokenGranularScope',
};

export const mockGranularUserScope = {
  access: 'USER',
  namespace: null,
  permissions: [
    { resource: 'profile', action: 'read' },
    { resource: 'profile', action: 'create' },
  ],
  __typename: 'AccessTokenGranularScope',
};

export const mockGranularInstanceScope = {
  access: 'INSTANCE',
  namespace: null,
  permissions: [
    { resource: 'admin_member_role', action: 'read' },
    { resource: 'admin_member_role', action: 'create' },
  ],
  __typename: 'AccessTokenGranularScope',
};

export const mockLegacyScopes = [
  { value: 'api', __typename: 'AccessTokenLegacyScope' },
  { value: 'read_user', __typename: 'AccessTokenLegacyScope' },
];

export const mockTokens = [
  {
    id: 'gid://gitlab/PersonalAccessToken/1',
    name: 'Token 1',
    description: 'Test token 1',
    active: true,
    revoked: false,
    expiresAt: '2025-12-31',
    lastUsedAt: '2025-11-01T10:00:00Z',
    createdAt: '2025-10-01T10:00:00Z',
    lastUsedIps: ['192.168.1.1', '192.168.0.0'],
    granular: true,
    scopes: [mockGranularGroupScope],
  },
  {
    id: 'gid://gitlab/PersonalAccessToken/2',
    name: 'Token 2',
    description: null,
    active: false,
    revoked: true,
    expiresAt: null,
    lastUsedAt: null,
    createdAt: '2025-02-01',
    lastUsedIps: [],
    granular: false,
    scopes: mockLegacyScopes,
  },
];

export const mockPageInfo = {
  hasNextPage: true,
  hasPreviousPage: false,
  startCursor: 'eyJpZCI6IjUxIn0',
  endCursor: 'eyJpZCI6IjM1In0',
  __typename: 'PageInfo',
};

export const mockQueryResponse = {
  data: {
    user: {
      id: 'gid://gitlab/User/123',
      personalAccessTokens: {
        nodes: mockTokens,
        pageInfo: mockPageInfo,
      },
    },
  },
};

export const mockCreateMutationInput = {
  name: 'Test Token',
  description: 'Test description',
  expirationDate: '2025-12-31',
  group: {
    access: 'SELECTED_MEMBERSHIPS',
    resourceIds: ['gid://gitlab/Project/1', 'gid://gitlab/Group/1'],
    permissions: ['read_project', 'write_project'],
  },
  user: {
    access: 'USER',
    permissions: ['read_user', 'follow_user'],
  },
};

export const mockCreateMutationResponse = {
  data: {
    personalAccessTokenCreate: {
      errors: [],
      token: 'xx',
    },
  },
};

export const mockRotateMutationResponse = {
  data: {
    personalAccessTokenRotate: {
      errors: [],
      token: 'xx',
    },
  },
};

export const mockRevokeMutationResponse = {
  data: {
    personalAccessTokenRevoke: {
      errors: [],
    },
  },
};

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
    nameWithNamespace: 'Test / Test Project 1',
    fullPath: 'test-group-1/test-project-1',
    __typename: 'Project',
  },
  {
    id: 'gid://gitlab/Project/2',
    name: 'Test Project 2',
    nameWithNamespace: 'Test / Test Project 2',
    fullPath: 'test-group-2/test-project-2',
    __typename: 'Project',
  },
];

export const mockSearchGroupsAndProjectsQueryResponse = {
  data: {
    projects: {
      nodes: mockProjects,
    },
    user: {
      id: 'gid://gitlab/User/123',
      groups: {
        nodes: mockGroups,
      },
    },
  },
};

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
];

export const mockGroupResources = ['project', 'repository'];

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

export const mockAccessTokenPermissionsQueryResponse = {
  data: {
    accessTokenPermissions: [
      ...mockGroupPermissions,
      ...mockUserPermissions,
      ...mockInstancePermissions,
    ],
  },
};
export const mockStatisticsResponse = {
  data: {
    user: {
      id: 'gid://gitlab/User/123',
      active: { count: 5 },
      expiringSoon: { count: 2 },
      revoked: { count: 3 },
      expired: { count: 1 },
    },
  },
};
