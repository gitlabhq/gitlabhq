export default {
  __typename: 'Pipeline',
  id: 195,
  iid: '5',
  retryable: false,
  cancelable: false,
  userPermissions: {
    updatePipeline: true,
  },
  path: '/root/elemenohpee/-/pipelines/195',
  status: {
    __typename: 'DetailedStatus',
    group: 'success',
    label: 'passed',
    icon: 'status_success',
  },
  sourceJob: {
    __typename: 'CiJob',
    name: 'test_c',
  },
  project: {
    __typename: 'Project',
    name: 'elemenohpee',
    fullPath: 'root/elemenohpee',
  },
  multiproject: true,
};
