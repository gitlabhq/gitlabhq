export const firstExperiment = {
  id: 'gid://gitlab/Ml::Experiment/1',
  name: 'experiment-1',
  updatedAt: '2021-08-10T09:33:54Z',
  candidateCount: 10,
  path: 'experiment/path/1',
  modelId: 'gid://gitlab/Ml::Experiment/10',
  creator: {
    id: 'gid://gitlab/User/9998',
    name: 'Jane Doe',
    webUrl: 'jane/web/url',
    avatarUrl: 'jane/avatar/url',
  },
};

export const secondExperiment = {
  id: 'gid://gitlab/Ml::Experiment/2',
  name: 'experiment-2',
  updatedAt: '2021-08-10T09:39:54Z',
  candidateCount: 10,
  path: 'experiment/path/1',
  modelId: 'gid://gitlab/Ml::Experiment/11',
  creator: {
    id: 'gid://gitlab/User/9999',
    name: 'John Doe',
    webUrl: 'john/web/url',
    avatarUrl: 'john/avatar/url',
  },
};

export const thirdExperiment = {
  id: 'gid://gitlab/Ml::Experiment/3',
  name: 'experiment-3',
  updatedAt: '2025-10-14T09:33:54Z',
  candidateCount: 12,
  path: 'experiment/path/3',
  modelId: 'gid://gitlab/Ml::Experiment/11',
  creator: null,
};

export const MockExperimentsQueryResult = {
  data: {
    project: {
      id: 111,
      mlExperiments: {
        count: 3,
        nodes: [firstExperiment, secondExperiment, thirdExperiment],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: 'endCursor',
          startCursor: 'startCursor',
        },
      },
    },
  },
};

export const MockExperimentsEmptyQueryResult = {
  data: {
    project: {
      id: 111,
      mlExperiments: {
        count: 0,
        nodes: [],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: 'endCursor',
          startCursor: 'startCursor',
        },
      },
    },
  },
};
