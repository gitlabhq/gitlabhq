export const startCursor = 'eyJpZCI6IjE2In0';
export const defaultPageInfo = Object.freeze({
  startCursor,
  endCursor: 'eyJpZCI6IjIifQ',
  hasNextPage: true,
  hasPreviousPage: true,
});

export const firstExperiment = Object.freeze({
  name: 'Experiment 1',
  path: 'path/to/experiment/1',
  candidate_count: 2,
  updated_at: '2021-04-01',
  user: {
    id: 1,
    name: 'Joe Doe',
    path: 'namespace1',
    avatar_url: 'avatar_url',
  },
});

export const secondExperiment = Object.freeze({
  name: 'Experiment 2',
  path: 'path/to/experiment/2',
  candidate_count: 3,
  updated_at: '2021-04-01',
  user: {
    id: 1,
    name: 'Jane Doe',
    path: 'namespace1',
    avatar_url: 'avatar_url',
  },
});

export const experiments = [firstExperiment, secondExperiment];
