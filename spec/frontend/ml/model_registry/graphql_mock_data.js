import { defaultPageInfo } from './mock_data';

export const graphqlPageInfo = {
  ...defaultPageInfo,
  __typename: 'PageInfo',
};

export const graphqlModelVersions = [
  {
    createdAt: '2021-08-10T09:33:54Z',
    author: {
      id: 'gid://gitlab/User/1',
      name: 'Root',
      avatarUrl: 'path/to/avatar',
      webUrl: 'path/to/user',
    },
    id: 'gid://gitlab/Ml::ModelVersion/243',
    version: '1.0.1',
    _links: {
      showPath: '/path/to/modelversion/243',
    },
    __typename: 'MlModelVersion',
  },
  {
    createdAt: '2021-08-10T09:33:54Z',
    author: {
      id: 'gid://gitlab/User/1',
      name: 'Root',
      avatarUrl: 'path/to/avatar',
      webUrl: 'path/to/user',
    },
    id: 'gid://gitlab/Ml::ModelVersion/244',
    version: '1.0.2',
    _links: {
      showPath: '/path/to/modelversion/244',
    },
    __typename: 'MlModelVersion',
  },
];

export const modelVersionsQuery = (versions = graphqlModelVersions) => ({
  data: {
    mlModel: {
      id: 'gid://gitlab/Ml::Model/2',
      versions: {
        count: versions.length,
        nodes: versions,
        pageInfo: graphqlPageInfo,
        __typename: 'MlModelConnection',
      },
      __typename: 'MlModelType',
    },
  },
});

export const candidate = {
  id: 'gid://gitlab/Ml::Candidate/1',
  name: 'hare-zebra-cobra-9745',
  iid: 1,
  eid: 'e9a71521-45c6-4b0a-b0c3-21f0b4528a5c',
  status: 'running',
  params: {
    nodes: [
      {
        id: 'gid://gitlab/Ml::CandidateParam/1',
        name: 'param1',
        value: 'value1',
      },
    ],
  },
  metadata: {
    nodes: [
      {
        id: 'gid://gitlab/Ml::CandidateMetadata/1',
        name: 'metadata1',
        value: 'metadataValue1',
      },
    ],
  },
  metrics: {
    nodes: [
      {
        id: 'gid://gitlab/Ml::CandidateMetric/1',
        name: 'metric1',
        value: 0.3,
        step: 0,
      },
    ],
  },
  ciJob: {
    id: 'gid://gitlab/Ci::Build/1',
    webPath: '/gitlab-org/gitlab-test/-/jobs/1',
    name: 'build:linux',
    pipeline: {
      id: 'gid://gitlab/Ci::Pipeline/1',
      mergeRequest: {
        id: 'gid://gitlab/MergeRequest/1',
        title: 'Merge Request 1',
        webUrl: 'path/to/mr',
        iid: 1,
      },
      user: {
        id: 'gid://gitlab/User/1',
        avatarUrl: 'path/to/avatar',
        webUrl: 'path/to/user/1',
        username: 'user1',
        name: 'User 1',
      },
    },
  },
  _links: {
    showPath: '/root/test-project/-/ml/candidates/1',
    artifactPath: '/root/test-project/-/packages/1',
  },
};

export const modelVersionWithCandidate = {
  id: 'gid://gitlab/Ml::ModelVersion/1',
  version: '1.0.4999',
  packageId: 'gid://gitlab/Packages::Package/12',
  description: 'A model version description',
  descriptionHtml: 'A model version description',
  candidate,
  _links: {
    showPath: '/root/test-project/-/ml/models/1/versions/5000',
  },
};

export const modelVersionWithCandidateAndAuthor = {
  id: 'gid://gitlab/Ml::ModelVersion/1',
  artifactsCount: 1,
  author: {
    id: 'gid://gitlab/User/1',
    name: 'Root',
    avatarUrl: 'path/to/avatar',
    webUrl: 'path/to/user',
  },
  createdAt: '2023-12-06T12:41:48Z',
  version: '1.0.4999',
  packageId: 'gid://gitlab/Packages::Package/12',
  description: 'A model version description',
  descriptionHtml: 'A model version description',
  candidate,
  _links: {
    showPath: '/root/test-project/-/ml/models/1/versions/5000',
  },
};

export const modelVersionWithCandidateAndNullAuthor = {
  ...modelVersionWithCandidateAndAuthor,
  author: null,
};

export const graphqlCandidates = [
  {
    id: 'gid://gitlab/Ml::Candidate/1',
    eid: 'e9a71521-45c6-4b0a-b0c3-21f0b4528a5c',
    creator: {
      id: 'gid://gitlab/User/1',
      webUrl: 'path/to/user',
      avatarUrl: 'path/to/avatar',
      name: 'Root',
    },
    ciJob: {
      id: 'gid://gitlab/Ci::Build/1',
      name: 'build:linux',
      webPath: '/path/to/candidate/1',
    },
    status: 'running',
    name: 'narwhal-aardvark-heron-6953',
    createdAt: '2023-12-06T12:41:48Z',
    _links: {
      showPath: '/path/to/candidate/1',
    },
  },
  {
    id: 'gid://gitlab/Ml::Candidate/2',
    eid: 'e9a71521-45c6-4b0a-b0c3-21f0b4528a4c',
    creator: {
      id: 'gid://gitlab/User/1',
      webUrl: 'path/to/user',
      avatarUrl: 'path/to/avatar',
      name: 'Root',
    },
    ciJob: {
      id: 'gid://gitlab/Ci::Build/2',
      name: 'build:linux',
      webPath: '/path/to/candidate/2',
    },
    status: 'failed',
    name: 'anteater-chimpanzee-snake-1254',
    createdAt: '2023-12-06T12:41:48Z',
    _links: {
      showPath: '/path/to/candidate/2',
    },
  },
];

export const modelCandidatesQuery = (candidates = graphqlCandidates) => ({
  data: {
    mlModel: {
      id: 'gid://gitlab/Ml::Model/2',
      candidates: {
        count: candidates.length,
        nodes: candidates,
        pageInfo: graphqlPageInfo,
        __typename: 'MlCandidateConnection',
      },
      __typename: 'MlModelType',
    },
  },
});

export const emptyModelVersionsQuery = {
  data: {
    mlModel: {
      id: 'gid://gitlab/Ml::Model/2',
      versions: {
        count: 0,
        nodes: [],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: 'endCursor',
          startCursor: 'startCursor',
        },
        __typename: 'MlModelConnection',
      },
      __typename: 'MlModelType',
    },
  },
};

export const emptyCandidateQuery = {
  data: {
    mlModel: {
      id: 'gid://gitlab/Ml::Model/2',
      candidates: {
        count: 0,
        nodes: [],
        creator: {},
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: 'endCursor',
          startCursor: 'startCursor',
        },
        __typename: 'MlCandidateConnection',
      },
      __typename: 'MlModelType',
    },
  },
};

export const createModelResponses = {
  success: {
    data: {
      mlModelCreate: {
        model: {
          id: 'gid://gitlab/Ml::Model/1',
          _links: {
            showPath: '/some/project/-/ml/models/1',
          },
        },
        errors: [],
      },
    },
  },
  validationFailure: {
    data: {
      mlModelCreate: {
        model: null,
        errors: ['Name is invalid', "Name can't be blank"],
      },
    },
  },
};

export const editModelResponses = {
  success: {
    data: {
      mlModelEdit: {
        model: {
          id: 'gid://gitlab/Ml::Model/1',
          _links: {
            showPath: '/some/project/-/ml/models/1',
          },
        },
        errors: [],
      },
    },
  },
  validationFailure: {
    data: {
      mlModelEdit: {
        model: null,
        errors: ['Unable to update model'],
      },
    },
  },
};

export const editModelVersionResponses = {
  success: {
    data: {
      mlModelVersionEdit: {
        modelVersion: {
          id: 'gid://gitlab/Ml::ModelVersion/1',
          _links: {
            showPath: '/some/project/-/ml/models/1',
          },
        },
        errors: [],
      },
    },
  },
  validationFailure: {
    data: {
      mlModelVersionEdit: {
        modelVersion: null,
        errors: ['Unable to update model version'],
      },
    },
  },
};

export const destroyModelResponses = {
  success: {
    data: {
      mlModelDelete: {
        errors: [],
      },
    },
  },
  failure: {
    data: {
      mlModelDelete: {
        errors: ['Model not found'],
      },
    },
  },
};

export const modelWithVersions = {
  id: 'gid://gitlab/Ml::Model/1',
  name: 'model_1',
  versionCount: 2,
  createdAt: '2023-12-06T12:41:48Z',
  latestVersion: {
    id: 'gid://gitlab/Ml::ModelVersion/1',
    version: '1.0.0',
    _links: {
      showPath: '/my_project/-/ml/models/1/versions/1',
    },
  },
  _links: {
    showPath: '/my_project/-/ml/models/1',
  },
};

export const modelWithOneVersion = {
  id: 'gid://gitlab/Ml::Model/2',
  name: 'model_2',
  versionCount: 1,
  createdAt: '2023-12-06T12:41:48Z',
  author: {
    id: 'gid://gitlab/User/1',
    name: 'name',
    avatarUrl: 'avatarUrl',
    webUrl: 'webUrl',
  },
  latestVersion: {
    id: 'gid://gitlab/Ml::ModelVersion/1',
    version: '1.0.0',
    _links: {
      showPath: '/my_project/-/ml/models/2/versions/1',
    },
  },
  _links: {
    showPath: '/my_project/-/ml/models/2',
  },
};

export const modelWithoutVersion = {
  id: 'gid://gitlab/Ml::Model/3',
  name: 'model_3',
  versionCount: 0,
  latestVersion: null,
  createdAt: '2023-12-06T12:41:48Z',
  author: {
    id: 'gid://gitlab/User/1',
    name: 'name',
    avatarUrl: 'avatarUrl',
    webUrl: 'webUrl',
  },
  _links: {
    showPath: '/my_project/-/ml/models/3',
  },
};

export const model = {
  id: 'gid://gitlab/Ml::Model/1',
  createdAt: '2023-12-06T12:41:48Z',
  author: {
    id: 'gid://gitlab/User/1',
    name: 'Root',
    avatarUrl: 'path/to/avatar',
    webUrl: 'path/to/user',
  },
  defaultExperimentPath: 'path/to/experiment',
  description: 'A model description',
  descriptionHtml: 'A model description',
  name: 'gitlab_amazing_model',
  versionCount: 1,
  candidateCount: 0,
  latestVersion: modelVersionWithCandidateAndAuthor,
};

export const modelWithNoVersion = {
  id: 'gid://gitlab/Ml::Model/3',
  name: 'model_3',
  versionCount: 0,
  latestVersion: null,
  createdAt: '2023-12-06T12:41:48Z',
  description: 'A model description',
  descriptionHtml: 'A model description',
  defaultExperimentPath: 'path/to/experiment',
  author: {
    id: 'gid://gitlab/User/1',
    name: 'name',
    avatarUrl: 'avatarUrl',
    webUrl: 'webUrl',
  },
  _links: {
    showPath: '/my_project/-/ml/models/3',
  },
  candidateCount: 0,
};

export const modelDetailQuery = {
  data: {
    mlModel: model,
  },
};

export const modelWithNoVersionDetailQuery = {
  data: {
    mlModel: modelWithNoVersion,
  },
};

export const modelWithVersion = {
  ...model,
  version: modelVersionWithCandidate,
};

export const modelsQuery = (
  models = [modelWithOneVersion, modelWithoutVersion],
  pageInfo = graphqlPageInfo,
) => ({
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      mlModels: {
        count: models.length,
        nodes: models,
        pageInfo,
      },
    },
  },
});

export const modelVersionQuery = {
  data: {
    mlModel: {
      id: 'gid://gitlab/Ml::Model/1',
      name: 'blah',
      version: modelVersionWithCandidate,
    },
  },
};

export const modelVersionQueryWithAuthor = {
  data: {
    mlModel: {
      id: 'gid://gitlab/Ml::Model/1',
      name: 'blah',
      version: modelVersionWithCandidateAndAuthor,
    },
  },
};

export const deleteModelVersionResponses = {
  success: {
    data: {
      mlModelVersionDelete: {
        errors: [],
      },
    },
  },
  failure: {
    data: {
      mlModelVersionDelete: {
        errors: ['Model version not found', 'Project not found'],
      },
    },
  },
};

export const createModelVersionResponses = {
  success: {
    data: {
      mlModelVersionCreate: {
        modelVersion: {
          id: 'gid://gitlab/Ml::ModelVersion/1',
          _links: {
            showPath: '/some/project/-/ml/models/1/versions/1',
            packagePath: '/some/project/-/packages/19',
            importPath: '/api/v4/projects/1/packages/ml_models/1/files/',
          },
        },
        errors: [],
      },
    },
  },
  failure: {
    data: {
      mlModelVersionCreate: {
        modelVersion: null,
        errors: ['Version is invalid'],
      },
    },
  },
};

export const graphqlModels = [model];
