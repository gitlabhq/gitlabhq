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

export const mockGranularGroupScope = {
  access: 'SELECTED_MEMBERSHIPS',
  namespace: {
    id: 'gid://gitlab/Group/1',
    name: 'My Group',
    fullName: 'My Group',
    fullPath: 'my-group',
    webUrl: 'https://gitlab.com/groups/my-group',
    avatarUrl: '/avatar.png',
    __typename: 'Group',
  },
  permissions: mockGroupPermissions,
  __typename: 'AccessTokenGranularScope',
};

export const mockGranularProjectScope = {
  access: 'SELECTED_MEMBERSHIPS',
  namespace: {
    id: 'gid://gitlab/Namespaces::ProjectNamespace/10',
    name: 'My Project',
    fullPath: 'my-group/my-project',
    __typename: 'Namespace',
  },
  project: {
    id: 'gid://gitlab/Project/10',
    name: 'My Project',
    fullPath: 'my-group/my-project',
    __typename: 'Project',
  },
  permissions: [{ resource: 'project', action: 'read', name: 'read_project' }],
  __typename: 'AccessTokenGranularScope',
};

export const mockGranularUserScope = {
  access: 'USER',
  namespace: null,
  project: null,
  permissions: mockUserPermissions,
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
export const mockGroupScopedTokenQueryResponse = {
  data: {
    user: {
      id: 'gid://gitlab/User/42',
      __typename: 'UserCore',
      personalAccessTokens: {
        __typename: 'PersonalAccessTokenConnection',
        nodes: [
          {
            id: 'gid://gitlab/PersonalAccessToken/1',
            __typename: 'PersonalAccessToken',
            name: mockTokens[0].name,
            description: mockTokens[0].description,
            granular: true,
            scopes: [{ ...mockGranularGroupScope, project: null }],
          },
        ],
      },
    },
  },
};

export const mockProjectScopedTokenQueryResponse = {
  data: {
    user: {
      id: 'gid://gitlab/User/42',
      __typename: 'UserCore',
      personalAccessTokens: {
        __typename: 'PersonalAccessTokenConnection',
        nodes: [
          {
            id: 'gid://gitlab/PersonalAccessToken/2',
            __typename: 'PersonalAccessToken',
            name: 'Project Token',
            description: 'A project-scoped token',
            granular: true,
            scopes: [mockGranularProjectScope],
          },
        ],
      },
    },
  },
};

export const mockUserScopedTokenQueryResponse = {
  data: {
    user: {
      id: 'gid://gitlab/User/42',
      __typename: 'UserCore',
      personalAccessTokens: {
        __typename: 'PersonalAccessTokenConnection',
        nodes: [
          {
            id: 'gid://gitlab/PersonalAccessToken/3',
            __typename: 'PersonalAccessToken',
            name: 'User Only Token',
            description: 'A user-scoped token',
            granular: true,
            scopes: [mockGranularUserScope],
          },
        ],
      },
    },
  },
};

export const mockSourceTokenQueryResponse = {
  data: {
    user: {
      id: 'gid://gitlab/User/42',
      __typename: 'UserCore',
      personalAccessTokens: {
        __typename: 'PersonalAccessTokenConnection',
        nodes: [
          {
            id: 'gid://gitlab/PersonalAccessToken/4',
            __typename: 'PersonalAccessToken',
            name: 'Namespace And User Scope Token',
            description: 'A token with both namespace and user scopes',
            granular: true,
            scopes: [mockGranularProjectScope, mockGranularUserScope],
          },
        ],
      },
    },
  },
};

export const mockNullDescriptionTokenQueryResponse = {
  data: {
    user: {
      id: 'gid://gitlab/User/42',
      __typename: 'UserCore',
      personalAccessTokens: {
        __typename: 'PersonalAccessTokenConnection',
        nodes: [
          {
            id: 'gid://gitlab/PersonalAccessToken/5',
            __typename: 'PersonalAccessToken',
            name: 'No Description Token',
            description: null,
            granular: true,
            scopes: [mockGranularUserScope],
          },
        ],
      },
    },
  },
};

export const mockLegacySourceTokenQueryResponse = {
  data: {
    user: {
      id: 'gid://gitlab/User/42',
      __typename: 'UserCore',
      personalAccessTokens: {
        __typename: 'PersonalAccessTokenConnection',
        nodes: [
          {
            id: 'gid://gitlab/PersonalAccessToken/2',
            __typename: 'PersonalAccessToken',
            name: mockTokens[1].name,
            description: mockTokens[1].description,
            granular: false,
            scopes: mockLegacyScopes,
          },
        ],
      },
    },
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
