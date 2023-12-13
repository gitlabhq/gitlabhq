import { defaultPageInfo } from './mock_data';

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

export const graphqlCandidates = [
  {
    id: 'gid://gitlab/Ml::Candidate/1',
    name: 'narwhal-aardvark-heron-6953',
    createdAt: '2023-12-06T12:41:48Z',
    _links: {
      showPath: '/path/to/candidate/1',
    },
  },
  {
    id: 'gid://gitlab/Ml::Candidate/2',
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
