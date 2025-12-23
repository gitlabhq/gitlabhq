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
