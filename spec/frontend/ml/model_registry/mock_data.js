export const newCandidate = (withModel = true) => ({
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
    gid: 'gid://gitlab/Ml::Candidate/1',
    pathToArtifact: 'path_to_artifact/packages/12',
    experimentName: 'The Experiment',
    pathToExperiment: 'path/to/experiment',
    status: 'finished',
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
    createdAt: '2024-01-01T00:00:00Z',
    authorName: 'Test User',
    authorWebUrl: '/test-user',
    canPromote: true,
    promotePath: 'promote/path',
  },
  projectPath: 'some/project',
  canWriteModelRegistry: true,
  canWriteModelExperiments: true,
  markdownPreviewPath: '/markdown-preview',
  modelGid: withModel ? 'gid://gitlab/Ml::Model/1' : undefined,
  modelName: withModel ? 'CoolModel' : undefined,
  latestVersion: withModel ? '1.0.2' : undefined,
});

export const startCursor = 'eyJpZCI6IjE2In0';

export const defaultPageInfo = Object.freeze({
  startCursor,
  endCursor: 'eyJpZCI6IjIifQ',
  hasNextPage: true,
  hasPreviousPage: true,
});
