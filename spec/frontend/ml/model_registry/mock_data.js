export const newCandidate = () => ({
  params: [
    { name: 'Algorithm', value: 'Decision Tree' },
    { name: 'MaxDepth', value: '3' },
  ],
  metrics: [
    { name: 'AUC', value: '.55', step: 0 },
    { name: 'Accuracy', value: '.99', step: 1 },
    { name: 'Accuracy', value: '.98', step: 2 },
    { name: 'Accuracy', value: '.97', step: 3 },
    { name: 'F1', value: '.1', step: 3 },
  ],
  metadata: [
    { name: 'FileName', value: 'test.py' },
    { name: 'ExecutionTime', value: '.0856' },
  ],
  info: {
    iid: 'candidate_iid',
    eid: 'abcdefg',
    pathToArtifact: 'path_to_artifact',
    experimentName: 'The Experiment',
    pathToExperiment: 'path/to/experiment',
    status: 'SUCCESS',
    path: 'path_to_candidate',
    ciJob: {
      name: 'test',
      path: 'path/to/job',
      mergeRequest: {
        path: 'path/to/mr',
        iid: 1,
        title: 'Some MR',
      },
      user: {
        path: 'path/to/ci/user',
        name: 'CI User',
        username: 'ciuser',
        avatar: '/img.png',
      },
    },
  },
});

const LATEST_VERSION = {
  version: '1.2.3',
};

export const makeModel = ({ latestVersion } = { latestVersion: LATEST_VERSION }) => ({
  id: 1234,
  name: 'blah',
  path: 'path/to/blah',
  description: 'Description of the model',
  latestVersion,
  versionCount: 2,
  candidateCount: 1,
});

export const MODEL = makeModel();

export const makeModelVersion = ({
  version = '1.2.3',
  model = MODEL,
  packageId = 12,
  description = 'Model version description',
} = {}) => ({
  version,
  model,
  packageId,
  description,
  projectPath: 'path/to/project',
  candidate: newCandidate(),
});

export const MODEL_VERSION = makeModelVersion();

export const mockModels = [
  {
    name: 'model_1',
    version: '1.0',
    versionPath: 'path/to/version',
    path: 'path/to/model_1',
    versionCount: 3,
  },
  {
    name: 'model_2',
    version: '1.1',
    path: 'path/to/model_2',
    versionCount: 1,
  },
];

export const modelWithoutVersion = {
  name: 'model_without_version',
  path: 'path/to/model_without_version',
  versionCount: 0,
};

export const startCursor = 'eyJpZCI6IjE2In0';

export const defaultPageInfo = Object.freeze({
  startCursor,
  endCursor: 'eyJpZCI6IjIifQ',
  hasNextPage: true,
  hasPreviousPage: true,
});

export const graphqlPageInfo = {
  ...defaultPageInfo,
  __typename: 'PageInfo',
};

export const graphqlModelVersions = [
  {
    createdAt: '2021-08-10T09:33:54Z',
    id: 'gid://gitlab/Ml::ModelVersion/243',
    version: '1.0.1',
    _links: {
      showPath: '/path/to/modelversion/243',
    },
    __typename: 'MlModelVersion',
  },
  {
    createdAt: '2021-08-10T09:33:54Z',
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
