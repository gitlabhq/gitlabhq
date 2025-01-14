import { graphqlCandidates, graphqlPageInfo } from 'jest/ml/model_registry/graphql_mock_data';

export const experimentCandidatesQuery = (candidates = graphqlCandidates) => ({
  data: {
    mlExperiment: {
      id: 'gid://gitlab/Ml::Experiment/1',
      candidates: {
        count: candidates.length,
        nodes: candidates,
        pageInfo: graphqlPageInfo,
        __typename: 'MlCandidateConnection',
      },
      __typename: 'MlExperimentType',
    },
  },
});

export const emptyCandidateQuery = {
  data: {
    mlExperiment: {
      id: 'gid://gitlab/Ml::Experiment/1',
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
      __typename: 'MlExperimentType',
    },
  },
};
