const userPermissionsData = {
  userPermissions: {
    destroyContainerRepository: true,
  },
};

export const imagesListResponse = [
  {
    __typename: 'ContainerRepository',
    id: 'gid://gitlab/ContainerRepository/26',
    name: 'rails-12009',
    path: 'gitlab-org/gitlab-test/rails-12009',
    status: null,
    migrationState: 'default',
    location: '0.0.0.0:5000/gitlab-org/gitlab-test/rails-12009',
    createdAt: '2020-05-17T14:23:32Z',
    expirationPolicyStartedAt: null,
    expirationPolicyCleanupStatus: 'UNSCHEDULED',
    project: {
      id: 'gid://gitlab/Project/22',
      name: 'gitlab-test',
      path: 'GITLAB-TEST',
      webUrl: 'http://localhost:3000/gitlab-org/gitlab-test',
    },
    protectionRuleExists: false,
    ...userPermissionsData,
  },
  {
    __typename: 'ContainerRepository',
    id: 'gid://gitlab/ContainerRepository/11',
    name: 'rails-20572',
    path: 'gitlab-org/gitlab-test/rails-20572',
    status: null,
    migrationState: 'default',
    location: '0.0.0.0:5000/gitlab-org/gitlab-test/rails-20572',
    createdAt: '2020-09-21T06:57:43Z',
    expirationPolicyStartedAt: null,
    expirationPolicyCleanupStatus: 'UNSCHEDULED',
    project: {
      id: 'gid://gitlab/Project/22',
      name: 'gitlab-test',
      path: 'GITLAB-TEST',
      webUrl: 'http://localhost:3000/gitlab-org/gitlab-test',
    },
    protectionRuleExists: false,
    ...userPermissionsData,
  },
];

export const pageInfo = {
  hasNextPage: true,
  hasPreviousPage: true,
  startCursor: 'eyJpZCI6IjI2In0',
  endCursor: 'eyJpZCI6IjgifQ',
  __typename: 'PageInfo',
};

export const graphQLImageListMock = {
  data: {
    project: {
      __typename: 'Project',
      id: '1',
      containerRepositoriesCount: 2,
      containerRepositories: {
        __typename: 'ContainerRepositoryConnection',
        nodes: imagesListResponse,
        pageInfo,
      },
    },
  },
};

export const graphQLEmptyImageListMock = {
  data: {
    project: {
      __typename: 'Project',
      id: '1',
      containerRepositoriesCount: 2,
      containerRepositories: {
        __typename: 'ContainerRepositoryConnection',
        nodes: [],
        pageInfo,
      },
    },
  },
};

export const graphQLEmptyGroupImageListMock = {
  data: {
    group: {
      __typename: 'Group',
      id: '1',
      containerRepositoriesCount: 2,
      containerRepositories: {
        __typename: 'ContainerRepositoryConnection',
        nodes: [],
        pageInfo,
      },
    },
  },
};

export const graphQLImageListNullContainerRepositoriesMock = {
  data: {
    project: {
      __typename: 'Project',
      id: '1',
      containerRepositoriesCount: 0,
      containerRepositories: null,
    },
  },
};

export const graphQLGroupImageListNullContainerRepositoriesMock = {
  data: {
    group: {
      __typename: 'Group',
      id: '1',
      containerRepositoriesCount: 0,
      containerRepositories: null,
    },
  },
};

export const deletedContainerRepository = {
  id: 'gid://gitlab/ContainerRepository/11',
  status: 'DELETE_SCHEDULED',
  path: 'gitlab-org/gitlab-test/rails-12009',
  __typename: 'ContainerRepository',
};

export const graphQLImageDeleteMock = {
  data: {
    destroyContainerRepository: {
      containerRepository: {
        ...deletedContainerRepository,
      },
      errors: [],
      __typename: 'DestroyContainerRepositoryPayload',
    },
  },
};

export const graphQLImageDeleteMockError = {
  data: {
    destroyContainerRepository: {
      containerRepository: {
        ...deletedContainerRepository,
      },
      errors: ['foo'],
      __typename: 'DestroyContainerRepositoryPayload',
    },
  },
};

export const containerRepositoryMock = {
  id: 'gid://gitlab/ContainerRepository/26',
  name: 'rails-12009',
  path: 'gitlab-org/gitlab-test/rails-12009',
  status: null,
  location: 'host.docker.internal:5000/gitlab-org/gitlab-test/rails-12009',
  createdAt: '2020-11-03T13:29:21Z',
  expirationPolicyStartedAt: null,
  expirationPolicyCleanupStatus: 'UNSCHEDULED',
  protectionRuleExists: false,
  project: {
    visibility: 'public',
    path: 'gitlab-test',
    id: '1',
    containerTagsExpirationPolicy: {
      enabled: false,
      nextRunAt: '2020-11-27T08:59:27Z',
    },
    __typename: 'Project',
  },
  ...userPermissionsData,
};

export const tagsPageInfo = {
  __typename: 'PageInfo',
  hasNextPage: true,
  hasPreviousPage: true,
  startCursor: 'MQ',
  endCursor: 'MTA',
};

export const tagsMock = [
  {
    digest: 'sha256:2cf3d2fdac1b04a14301d47d51cb88dcd26714c74f91440eeee99ce399089062',
    location: 'host.docker.internal:5000/gitlab-org/gitlab-test/rails-12009:beta-24753',
    path: 'gitlab-org/gitlab-test/rails-12009:beta-24753',
    name: 'beta-24753',
    revision: 'c2613843ab33aabf847965442b13a8b55a56ae28837ce182627c0716eb08c02b',
    shortRevision: 'c2613843a',
    createdAt: '2020-11-03T13:29:38+00:00',
    publishedAt: '2020-11-05T13:29:38+00:00',
    totalSize: '1099511627776',
    referrers: null,
    mediaType: null,
    userPermissions: {
      destroyContainerRepositoryTag: true,
    },
    protection: {
      minimumAccessLevelForPush: null,
      minimumAccessLevelForDelete: null,
    },
    __typename: 'ContainerRepositoryTag',
  },
  {
    digest: 'sha256:7f94f97dff89ffd122cafe50cd32329adf682356a7a96f69cbfe313ee589791c',
    location: 'host.docker.internal:5000/gitlab-org/gitlab-test/rails-12009:beta-31075',
    path: 'gitlab-org/gitlab-test/rails-12009:beta-31075',
    name: 'beta-31075',
    revision: 'df44e7228f0f255c73e35b6f0699624a615f42746e3e8e2e4b3804a6d6fc3292',
    shortRevision: 'df44e7228',
    createdAt: '2020-11-03T13:29:32+00:00',
    publishedAt: '2020-11-05T13:29:32+00:00',
    totalSize: '536870912000',
    referrers: null,
    mediaType: null,
    userPermissions: {
      destroyContainerRepositoryTag: true,
    },
    protection: {
      minimumAccessLevelForPush: null,
      minimumAccessLevelForDelete: null,
    },
    __typename: 'ContainerRepositoryTag',
  },
  {
    digest: 'sha256:2cf3d2fdac1b04a14301d47d51cb88dcd26714c74f91440eeee99ce399089062',
    location: 'host.docker.internal:5000/gitlab-org/gitlab-test/rails-12009:beta-24753',
    path: 'gitlab-org/gitlab-test/rails-12009:beta-24753',
    name: 'beta-24753',
    revision: 'c2613843ab33aabf847965442b13a8b55a56ae28837ce182627c0716eb08c02b',
    shortRevision: 'c2613843a',
    createdAt: '2020-11-03T13:29:38+00:00',
    publishedAt: '2020-11-05T13:29:38+00:00',
    totalSize: '1099511627776',
    referrers: null,
    mediaType: 'application/vnd.oci.image.index.v1+json',
    userPermissions: {
      destroyContainerRepositoryTag: true,
    },
    protection: {
      minimumAccessLevelForPush: null,
      minimumAccessLevelForDelete: null,
    },
    __typename: 'ContainerRepositoryTag',
  },
  {
    digest: 'sha256:2cf3d2fdac1b04a14301d47d51cb88dcd26714c74f91440eeee99ce399089062',
    location: 'host.docker.internal:5000/gitlab-org/gitlab-test/rails-12009:beta-24753',
    path: 'gitlab-org/gitlab-test/rails-12009:beta-24753',
    name: 'beta-24753',
    revision: 'c2613843ab33aabf847965442b13a8b55a56ae28837ce182627c0716eb08c02b',
    shortRevision: 'c2613843a',
    createdAt: '2020-11-03T13:29:38+00:00',
    publishedAt: '2020-11-05T13:29:38+00:00',
    totalSize: '1099511627776',
    referrers: null,
    mediaType: 'application/vnd.docker.distribution.manifest.list.v2+json',
    userPermissions: {
      destroyContainerRepositoryTag: true,
    },
    protection: {
      minimumAccessLevelForPush: null,
      minimumAccessLevelForDelete: null,
    },
    __typename: 'ContainerRepositoryTag',
  },
];

export const imageTagsMock = ({ nodes = tagsMock, userPermissions = {} } = {}) => ({
  data: {
    containerRepository: {
      id: containerRepositoryMock.id,
      tagsCount: nodes.length,
      tags: {
        nodes,
        pageInfo: { ...tagsPageInfo },
        __typename: 'ContainerRepositoryTagConnection',
      },
      userPermissions: {
        ...userPermissionsData.userPermissions,
        ...userPermissions,
      },
      __typename: 'ContainerRepositoryDetails',
    },
  },
});

export const imageTagsCountMock = (override) => ({
  data: {
    containerRepository: {
      id: containerRepositoryMock.id,
      tagsCount: 13,
      size: null,
      lastPublishedAt: '2020-11-05T13:29:32+00:00',
      protectionRuleExists: false,
      ...override,
    },
  },
});

export const graphQLImageDetailsMock = (override) => ({
  data: {
    containerRepository: {
      ...containerRepositoryMock,
      tagsCount: tagsMock.length,
      tags: {
        nodes: tagsMock,
        pageInfo: { ...tagsPageInfo },
        __typename: 'ContainerRepositoryTagConnection',
      },
      __typename: 'ContainerRepositoryDetails',
      ...override,
    },
  },
});

export const graphQLImageDetailsEmptyTagsMock = {
  data: {
    containerRepository: {
      ...containerRepositoryMock,
      tags: {
        nodes: [],
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: '',
          endCursor: '',
        },
        __typename: 'ContainerRepositoryTagConnection',
      },
      __typename: 'ContainerRepositoryDetails',
    },
  },
};

export const graphQLDeleteImageRepositoryTagsMock = {
  data: {
    destroyContainerRepositoryTags: {
      deletedTagNames: [],
      errors: [],
      __typename: 'DestroyContainerRepositoryTagsPayload',
    },
  },
};

export const dockerCommands = {
  dockerBuildCommand: 'foofoo',
  dockerPushCommand: 'barbar',
  dockerLoginCommand: 'bazbaz',
};

export const graphQLProjectImageRepositoriesDetailsMock = {
  data: {
    project: {
      id: '1',
      containerRepositories: {
        nodes: [
          {
            id: 'gid://gitlab/ContainerRepository/26',
            tagsCount: 4,
            __typename: 'ContainerRepository',
          },
          {
            id: 'gid://gitlab/ContainerRepository/11',
            tagsCount: 1,
            __typename: 'ContainerRepository',
          },
        ],
        __typename: 'ContainerRepositoryConnection',
      },
      __typename: 'Project',
    },
  },
};

export const graphQLEmptyImageDetailsMock = {
  data: {
    containerRepository: null,
  },
};
