export const MOCK_START_CURSOR = 'eyJpZCI6IjE2In0';

export const MOCK_PAGE_INFO = {
  startCursor: MOCK_START_CURSOR,
  endCursor: 'eyJpZCI6IjIifQ',
  hasNextPage: true,
  hasPreviousPage: true,
};

export const MOCK_EXPERIMENT = {
  id: 1,
  name: 'experiment',
  metadata: [],
  path: '/path/to/experiment',
  created_at: '2022-11-07T10:42:21.480Z',
  user: {
    name: 'root',
    path: '/root',
  },
};

export const MOCK_MODEL_EXPERIMENT = {
  id: 1,
  name: 'experiment',
  metadata: [],
  path: '/path/to/experiment',
  created_at: '2022-11-07T10:42:21.480Z',
  user: {
    name: 'root',
    path: '/root',
  },
  model_id: 1,
};

export const MOCK_EXPERIMENT_METADATA = [
  {
    id: 1,
    created_at: '2024-03-20T16:19:23.843Z',
    updated_at: '2024-03-20T16:19:23.843Z',
    experiment_id: 1,
    name: 'metadata_1',
    value: 'a',
  },
  {
    id: 2,
    created_at: '2024-03-20T16:19:23.848Z',
    updated_at: '2024-03-20T16:19:23.848Z',
    experiment_id: 1,
    name: 'metadata_2',
    value: 'b',
  },
];

export const MOCK_CANDIDATES = [
  {
    rmse: 1,
    l1_ratio: 0.4,
    details: 'link/to/candidate/1',
    artifact: 'link_to_artifact',
    ci_job: {
      path: 'link_to_job',
      name: 'a job',
    },
    name: 'aCandidate',
    created_at: '2023-01-05T14:07:01.975Z',
    user: { username: 'root', path: '/root' },
  },
  {
    auc: 0.3,
    l1_ratio: 0.5,
    details: 'link/to/candidate/2',
    created_at: '2023-01-05T14:07:02.975Z',
    name: null,
    user: null,
  },
  {
    auc: 0.4,
    l1_ratio: 0.5,
    details: 'link/to/candidate/3',
    created_at: '2023-01-05T14:07:03.975Z',
    name: null,
    user: null,
  },
  {
    auc: 0.6,
    l1_ratio: 0.5,
    details: 'link/to/candidate/4',
    created_at: '2023-01-05T14:07:04.975Z',
    name: null,
    user: null,
  },
  {
    auc: 0.5,
    l1_ratio: 0.5,
    details: 'link/to/candidate/5',
    created_at: '2023-01-05T14:07:05.975Z',
    name: null,
    user: null,
  },
];
