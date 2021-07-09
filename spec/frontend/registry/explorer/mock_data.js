export const imagesListResponse = [
  {
    __typename: 'ContainerRepository',
    id: 'gid://gitlab/ContainerRepository/26',
    name: 'rails-12009',
    path: 'gitlab-org/gitlab-test/rails-12009',
    status: null,
    location: '0.0.0.0:5000/gitlab-org/gitlab-test/rails-12009',
    canDelete: true,
    createdAt: '2020-11-03T13:29:21Z',
    expirationPolicyStartedAt: null,
    expirationPolicyCleanupStatus: 'UNSCHEDULED',
  },
  {
    __typename: 'ContainerRepository',
    id: 'gid://gitlab/ContainerRepository/11',
    name: 'rails-20572',
    path: 'gitlab-org/gitlab-test/rails-20572',
    status: null,
    location: '0.0.0.0:5000/gitlab-org/gitlab-test/rails-20572',
    canDelete: true,
    createdAt: '2020-09-21T06:57:43Z',
    expirationPolicyStartedAt: null,
    expirationPolicyCleanupStatus: 'UNSCHEDULED',
  },
];

export const pageInfo = {
  hasNextPage: true,
  hasPreviousPage: true,
  startCursor: 'eyJpZCI6IjI2In0',
  endCursor: 'eyJpZCI6IjgifQ',
  __typename: 'ContainerRepositoryConnection',
};

export const graphQLImageListMock = {
  data: {
    project: {
      __typename: 'Project',
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
      containerRepositoriesCount: 2,
      containerRepositories: {
        __typename: 'ContainerRepositoryConnection',
        nodes: [],
        pageInfo,
      },
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
  canDelete: true,
  createdAt: '2020-11-03T13:29:21Z',
  updatedAt: '2020-11-03T13:29:21Z',
  expirationPolicyStartedAt: null,
  expirationPolicyCleanupStatus: 'UNSCHEDULED',
  project: {
    visibility: 'public',
    containerExpirationPolicy: {
      enabled: false,
      nextRunAt: '2020-11-27T08:59:27Z',
    },
    __typename: 'Project',
  },
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
    totalSize: '1099511627776',
    canDelete: true,
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
    totalSize: '536870912000',
    canDelete: true,
    __typename: 'ContainerRepositoryTag',
  },
];

export const imageTagsMock = (nodes = tagsMock) => ({
  data: {
    containerRepository: {
      id: containerRepositoryMock.id,
      tags: {
        nodes,
        pageInfo: { ...tagsPageInfo },
        __typename: 'ContainerRepositoryTagConnection',
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
      ...override,
    },
  },
});

export const graphQLImageDetailsMock = (override) => ({
  data: {
    containerRepository: {
      ...containerRepositoryMock,

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
