export const newCandidate = () => ({
  params: [
    { name: 'Algorithm', value: 'Decision Tree' },
    { name: 'MaxDepth', value: '3' },
  ],
  metrics: [
    { name: 'AUC', value: '.55' },
    { name: 'Accuracy', value: '.99' },
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
  },
});
