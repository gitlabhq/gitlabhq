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

export const tagsListResponse = {
  data: [
    {
      name: 'centos6',
      revision: 'b118ab5b0e90b7cb5127db31d5321ac14961d097516a8e0e72084b6cdc783b43',
      short_revision: 'b118ab5b0',
      size: 19,
      layers: 10,
      location: 'location',
      path: 'bar:centos6',
      created_at: '2020-06-29T10:23:51.766+00:00',
      destroy_path: 'path',
      digest: 'sha256:1ab51d519f574b636ae7788051c60239334ae8622a9fd82a0cf7bae7786dfd5c',
    },
    {
      name: 'test-tag',
      revision: 'b969de599faea2b3d9b6605a8b0897261c571acaa36db1bdc7349b5775b4e0b4',
      short_revision: 'b969de599',
      size: 19,
      layers: 10,
      path: 'foo:test-tag',
      location: 'location-2',
      created_at: '2020-06-29T10:23:51.766+00:00',
      digest: 'sha256:1ab51d519f574b636ae7788051c60239334ae8622a9fd82a0cf7bae7736dfd5c',
    },
  ],
  headers,
};

export const pageInfo = {
  hasNextPage: true,
  hasPreviousPage: true,
  startCursor: 'eyJpZCI6IjI2In0',
  endCursor: 'eyJpZCI6IjgifQ',
  __typename: 'ContainerRepositoryConnection',
};

export const imageDetailsMock = {
  id: 1,
  name: 'rails-32309',
  path: 'gitlab-org/gitlab-test/rails-32309',
  project_id: 1,
  location: '0.0.0.0:5000/gitlab-org/gitlab-test/rails-32309',
  created_at: '2020-06-29T10:23:47.838Z',
  cleanup_policy_started_at: null,
  delete_api_path: 'http://0.0.0.0:3000/api/v4/projects/1/registry/repositories/1',
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
