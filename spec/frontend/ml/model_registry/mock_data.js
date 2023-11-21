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

export const MODEL_VERSION = { version: '1.2.3', model: MODEL };

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
    path_to_artifact: 'path_to_artifact',
    experiment_name: 'The Experiment',
    path_to_experiment: 'path/to/experiment',
    status: 'SUCCESS',
    path: 'path_to_candidate',
    ci_job: {
      name: 'test',
      path: 'path/to/job',
      merge_request: {
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
