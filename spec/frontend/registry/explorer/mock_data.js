export const headers = {
  'X-PER-PAGE': 5,
  'X-PAGE': 1,
  'X-TOTAL': 13,
  'X-TOTAL_PAGES': 1,
  'X-NEXT-PAGE': null,
  'X-PREVIOUS-PAGE': null,
};
export const reposServerResponse = [
  {
    destroy_path: 'path',
    id: '123',
    location: 'location',
    path: 'foo',
    tags_path: 'tags_path',
  },
  {
    destroy_path: 'path_',
    id: '456',
    location: 'location_',
    path: 'bar',
    tags_path: 'tags_path_',
  },
];

export const registryServerResponse = [
  {
    name: 'centos7',
    short_revision: 'b118ab5b0',
    revision: 'b118ab5b0e90b7cb5127db31d5321ac14961d097516a8e0e72084b6cdc783b43',
    total_size: 679,
    layers: 19,
    location: 'location',
    created_at: 1505828744434,
    destroy_path: 'path_',
  },
  {
    name: 'centos6',
    short_revision: 'b118ab5b0',
    revision: 'b118ab5b0e90b7cb5127db31d5321ac14961d097516a8e0e72084b6cdc783b43',
    total_size: 679,
    layers: 19,
    location: 'location',
    created_at: 1505828744434,
  },
];

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
    tagsCount: 18,
    expirationPolicyStartedAt: null,
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
    tagsCount: 1,
    expirationPolicyStartedAt: null,
  },
];

export const tagsListResponse = [
  {
    canDelete: true,
    createdAt: '2020-11-03T13:29:49+00:00',
    digest: 'sha256:9d72ae1db47404e44e1760eb1ca4cb427b84be8c511f05dfe2089e1b9f741dd7',
    location: 'host.docker.internal:5000/gitlab-org/gitlab-test/rails-12009:alpha-11821',
    name: 'alpha-11821',
    path: 'gitlab-org/gitlab-test/rails-12009:alpha-11821',
    revision: '5183b5d133fa864dca2de602f874b0d1bffe0f204ad894e3660432a487935139',
    shortRevision: '5183b5d13',
    totalSize: 104,
    layers: 10,
    __typename: 'ContainerRepositoryTag',
  },
  {
    canDelete: true,
    createdAt: '2020-11-03T13:29:48+00:00',
    digest: 'sha256:64f61282a71659f72066f9decd30b9038a465859b277a5e20da8681eb83e72f7',
    location: 'host.docker.internal:5000/gitlab-org/gitlab-test/rails-12009:alpha-20825',
    name: 'alpha-20825',
    path: 'gitlab-org/gitlab-test/rails-12009:alpha-20825',
    revision: 'e4212f1b73c6f9def2c37fa7df6c8d35c345fb1402860ff9a56404821aacf16f',
    shortRevision: 'e4212f1b7',
    totalSize: 105,
    layers: 10,
    __typename: 'ContainerRepositoryTag',
  },
];

export const pageInfo = {
  hasNextPage: true,
  hasPreviousPage: true,
  startCursor: 'eyJpZCI6IjI2In0',
  endCursor: 'eyJpZCI6IjgifQ',
  __typename: 'ContainerRepositoryConnection',
};

export const imageDetailsMock = {
  canDelete: true,
  createdAt: '2020-11-03T13:29:21Z',
  expirationPolicyStartedAt: null,
  id: 'gid://gitlab/ContainerRepository/26',
  location: 'host.docker.internal:5000/gitlab-org/gitlab-test/rails-12009',
  name: 'rails-12009',
  path: 'gitlab-org/gitlab-test/rails-12009',
  status: null,
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
  tagsCount: 13,
  expirationPolicyStartedAt: null,
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
    totalSize: 105,
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
    totalSize: 104,
    canDelete: true,
    __typename: 'ContainerRepositoryTag',
  },
];

export const graphQLImageDetailsMock = override => ({
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
